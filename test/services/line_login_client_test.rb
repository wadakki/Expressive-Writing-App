require "test_helper"

class LineLoginClientTest < ActiveSupport::TestCase
  test "builds an authorization URL with state nonce and OpenID scope" do
    client = build_client
    uri = URI(client.authorization_url(state: "state-123", nonce: "nonce-123"))
    params = URI.decode_www_form(uri.query).to_h

    assert_equal "https", uri.scheme
    assert_equal "access.line.me", uri.host
    assert_equal "/oauth2/v2.1/authorize", uri.path
    assert_equal "channel-id", params["client_id"]
    assert_equal "http://localhost:3000/line_connection/callback", params["redirect_uri"]
    assert_equal "state-123", params["state"]
    assert_equal "profile openid", params["scope"]
    assert_equal "nonce-123", params["nonce"]
    assert_equal "aggressive", params["bot_prompt"]
  end

  test "exchanges a code verifies the ID token and returns the user ID" do
    requests = []
    requester = lambda do |uri, params|
      requests << [ uri.to_s, params ]
      if uri.to_s == LineLoginClient::TOKEN_ENDPOINT
        [ 200, { id_token: "id-token" }.to_json ]
      else
        [ 200, { sub: "U123456", nonce: "nonce-123" }.to_json ]
      end
    end
    client = build_client(requester:)

    assert_equal "U123456", client.user_id(code: "authorization-code", nonce: "nonce-123")
    assert_equal LineLoginClient::TOKEN_ENDPOINT, requests.first.first
    assert_equal "authorization-code", requests.first.last[:code]
    assert_equal LineLoginClient::VERIFY_ENDPOINT, requests.second.first
    assert_equal "id-token", requests.second.last[:id_token]
  end

  test "rejects an invalid nonce" do
    requester = lambda do |uri, _params|
      body =
        if uri.to_s == LineLoginClient::TOKEN_ENDPOINT
          { id_token: "id-token" }
        else
          { sub: "U123456", nonce: "different-nonce" }
        end
      [ 200, body.to_json ]
    end

    assert_raises(LineLoginClient::AuthenticationError) do
      build_client(requester:).user_id(code: "code", nonce: "expected-nonce")
    end
  end

  test "raises a configuration error when settings are missing" do
    client = LineLoginClient.new(channel_id: "", channel_secret: "", redirect_uri: "")

    assert_raises(LineLoginClient::ConfigurationError) do
      client.authorization_url(state: "state", nonce: "nonce")
    end
  end

  test "raises an authentication error for a failed LINE response" do
    requester = ->(_uri, _params) { [ 400, { error: "invalid_grant" }.to_json ] }

    assert_raises(LineLoginClient::AuthenticationError) do
      build_client(requester:).user_id(code: "invalid-code", nonce: "nonce")
    end
  end

  private

  def build_client(requester: ->(_uri, _params) { raise "unexpected request" })
    LineLoginClient.new(
      channel_id: "channel-id",
      channel_secret: "channel-secret",
      redirect_uri: "http://localhost:3000/line_connection/callback",
      requester:
    )
  end
end
