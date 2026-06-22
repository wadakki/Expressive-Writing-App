require "test_helper"
require "minitest/mock"

class LineConnectionsControllerTest < ActionDispatch::IntegrationTest
  class FakeClient
    attr_reader :received_code, :received_nonce

    def initialize(user_id: "U-line-user", error: nil)
      @user_id = user_id
      @error = error
    end

    def authorization_url(state:, nonce:, bot_prompt:)
      query = URI.encode_www_form(state:, nonce:, bot_prompt:)
      "https://access.line.me/oauth2/v2.1/authorize?#{query}"
    end

    def user_id(code:, nonce:)
      raise @error if @error

      @received_code = code
      @received_nonce = nonce
      @user_id
    end
  end

  setup do
    @user = create_user(email: "line-linking@example.com")
    login_as(@user)
  end

  test "starts LINE Login with state and nonce" do
    client = FakeClient.new

    LineLoginClient.stub(:new, client) { get new_line_connection_url }

    assert_response :redirect
    uri = URI(response.location)
    params = URI.decode_www_form(uri.query).to_h
    assert_equal "access.line.me", uri.host
    assert params["state"].present?
    assert params["nonce"].present?
    assert_equal "aggressive", params["bot_prompt"]
  end

  test "shows a configuration error when LINE Login is not configured" do
    client = Object.new
    client.define_singleton_method(:authorization_url) do |**|
      raise LineLoginClient::ConfigurationError, "missing configuration"
    end

    LineLoginClient.stub(:new, client) { get new_line_connection_url }

    assert_redirected_to profile_url
    assert_equal "LINE Loginの設定が完了していません", flash[:alert]
  end

  test "links authentication and line connection after a valid callback" do
    client = FakeClient.new
    state = start_line_login(client)

    assert_difference([ "Authentication.count", "LineConnection.count" ], 1) do
      LineLoginClient.stub(:new, client) do
        get callback_line_connection_url, params: { code: "valid-code", state: }
      end
    end

    assert_redirected_to profile_url
    assert_equal "LINEアカウントを連携しました", flash[:notice]
    assert_equal "U-line-user", @user.authentications.find_by!(provider: "line").uid
    assert_equal "U-line-user", @user.line_connection.line_user_id
    assert_predicate @user.line_connection, :linked?
    assert_equal "valid-code", client.received_code
    assert client.received_nonce.present?
  end

  test "rejects an invalid state" do
    client = FakeClient.new
    start_line_login(client)

    assert_no_difference([ "Authentication.count", "LineConnection.count" ]) do
      LineLoginClient.stub(:new, client) do
        get callback_line_connection_url, params: { code: "valid-code", state: "invalid" }
      end
    end

    assert_redirected_to profile_url
    assert_equal "LINE認証の有効期限が切れました。もう一度お試しください", flash[:alert]
    assert_nil client.received_code
  end

  test "handles a LINE authentication error" do
    error = LineLoginClient::AuthenticationError.new("invalid token")
    client = FakeClient.new(error:)
    state = start_line_login(client)

    assert_no_difference([ "Authentication.count", "LineConnection.count" ]) do
      LineLoginClient.stub(:new, client) do
        get callback_line_connection_url, params: { code: "invalid-code", state: }
      end
    end

    assert_redirected_to profile_url
    assert_equal "LINE認証に失敗しました。もう一度お試しください", flash[:alert]
  end

  test "rejects a LINE account linked to another user" do
    other_user = create_user(email: "linked-owner@example.com")
    other_user.authentications.create!(provider: "line", uid: "U-line-user")
    other_user.create_line_connection!(line_user_id: "U-line-user", status: :linked)
    client = FakeClient.new
    state = start_line_login(client)

    assert_no_difference([ "Authentication.count", "LineConnection.count" ]) do
      LineLoginClient.stub(:new, client) do
        get callback_line_connection_url, params: { code: "valid-code", state: }
      end
    end

    assert_redirected_to profile_url
    assert_equal "このLINEアカウントはすでに連携されています", flash[:alert]
    assert_empty @user.authentications
    assert_nil @user.line_connection
  end

  test "handles an authorization cancellation" do
    client = FakeClient.new
    state = start_line_login(client)

    get callback_line_connection_url, params: { error: "access_denied", state: }

    assert_redirected_to profile_url
    assert_equal "LINE連携をキャンセルしました", flash[:alert]
  end

  test "disconnects authentication and line connection" do
    authentication = @user.authentications.create!(provider: "line", uid: "U-line-user")
    line_connection = @user.create_line_connection!(line_user_id: "U-line-user", status: :linked)

    delete line_connection_url

    assert_redirected_to profile_url
    assert_equal "LINE連携を解除しました", flash[:notice]
    assert_not Authentication.exists?(authentication.id)
    assert_not LineConnection.exists?(line_connection.id)
  end

  test "requires login" do
    delete logout_url

    get new_line_connection_url
    assert_redirected_to login_url

    delete line_connection_url
    assert_redirected_to login_url
  end

  private

  def start_line_login(client)
    LineLoginClient.stub(:new, client) { get new_line_connection_url }
    URI.decode_www_form(URI(response.location).query).to_h.fetch("state")
  end

  def create_user(email:)
    User.create!(
      name: "LINE連携ユーザー",
      email:,
      password: "password",
      password_confirmation: "password"
    )
  end

  def login_as(user)
    post login_url, params: {
      user_session: { email: user.email, password: "password" }
    }
  end
end
