require "test_helper"
require "minitest/mock"

class LineLoginsControllerTest < ActionDispatch::IntegrationTest
  class FakeClient
    attr_reader :received_code, :received_nonce

    def initialize(user_id: "U-line-login-user", error: nil)
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
    @user = User.create!(
      name: "LINEログインユーザー",
      email: "line-login@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @user.authentications.create!(provider: "line", uid: "U-line-login-user")
  end

  test "starts LINE Login with state and nonce" do
    client = FakeClient.new

    LineLoginClient.stub(:new, client) { get line_login_url }

    assert_response :redirect
    uri = URI(response.location)
    params = URI.decode_www_form(uri.query).to_h
    assert_equal "access.line.me", uri.host
    assert params["state"].present?
    assert params["nonce"].present?
    assert_equal "", params["bot_prompt"]
  end

  test "logs in a user associated with the LINE account" do
    client = FakeClient.new
    state = start_line_login(client)

    LineLoginClient.stub(:new, client) do
      get callback_line_connection_url, params: { code: "valid-code", state: }
    end

    assert_redirected_to root_url
    assert_equal "LINEアカウントでログインしました", flash[:notice]
    assert_equal "valid-code", client.received_code
    assert client.received_nonce.present?

    follow_redirect!
    assert_redirected_to writing_entries_url
  end

  test "does not log in an unlinked LINE account" do
    client = FakeClient.new(user_id: "U-unlinked-user")
    state = start_line_login(client)

    assert_no_difference("User.count") do
      LineLoginClient.stub(:new, client) do
        get callback_line_connection_url, params: { code: "valid-code", state: }
      end
    end

    assert_redirected_to login_url
    assert_equal "このLINEアカウントは連携されていません", flash[:alert]
  end

  test "rejects an invalid state" do
    client = FakeClient.new
    start_line_login(client)

    LineLoginClient.stub(:new, client) do
      get callback_line_connection_url, params: { code: "valid-code", state: "invalid" }
    end

    assert_redirected_to login_url
    assert_equal "LINE認証の有効期限が切れました。もう一度お試しください", flash[:alert]
    assert_nil client.received_code
  end

  test "handles a LINE authentication error" do
    error = LineLoginClient::AuthenticationError.new("invalid token")
    client = FakeClient.new(error:)
    state = start_line_login(client)

    LineLoginClient.stub(:new, client) do
      get callback_line_connection_url, params: { code: "invalid-code", state: }
    end

    assert_redirected_to login_url
    assert_equal "LINE認証に失敗しました。もう一度お試しください", flash[:alert]
  end

  test "handles an authorization cancellation" do
    client = FakeClient.new
    state = start_line_login(client)

    get callback_line_connection_url, params: { error: "access_denied", state: }

    assert_redirected_to login_url
    assert_equal "LINEログインをキャンセルしました", flash[:alert]
  end

  test "shows a configuration error when LINE Login is not configured" do
    client = Object.new
    client.define_singleton_method(:authorization_url) do |**|
      raise LineLoginClient::ConfigurationError, "missing configuration"
    end

    LineLoginClient.stub(:new, client) { get line_login_url }

    assert_redirected_to login_url
    assert_equal "LINE Loginの設定が完了していません", flash[:alert]
  end

  test "redirects an already logged in user without starting OAuth" do
    post login_url, params: {
      user_session: { email: @user.email, password: "password" }
    }

    LineLoginClient.stub(:new, -> { flunk("LINE Login should not start") }) do
      get line_login_url
    end

    assert_redirected_to root_url
  end

  private

  def start_line_login(client)
    LineLoginClient.stub(:new, client) { get line_login_url }
    URI.decode_www_form(URI(response.location).query).to_h.fetch("state")
  end
end
