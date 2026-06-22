require "test_helper"

class LineOauthSessionTest < ActiveSupport::TestCase
  test "starts and consumes a valid OAuth flow once" do
    session = {}
    oauth_session = LineOauthSession.new(session:)
    started = oauth_session.start(flow: LineOauthSession::LOGIN_FLOW)

    consumed = oauth_session.consume!(state: started[:state])

    assert_equal LineOauthSession::LOGIN_FLOW, consumed[:flow]
    assert_equal started[:nonce], consumed[:nonce]
    assert_nil session[LineOauthSession::SESSION_KEY]
    assert_raises(LineOauthSession::InvalidStateError) do
      oauth_session.consume!(state: started[:state])
    end
  end

  test "rejects an invalid state and clears the stored flow" do
    session = {}
    oauth_session = LineOauthSession.new(session:)
    oauth_session.start(flow: LineOauthSession::LINK_FLOW)

    assert_raises(LineOauthSession::InvalidStateError) do
      oauth_session.consume!(state: "invalid")
    end
    assert_nil session[LineOauthSession::SESSION_KEY]
  end

  test "rejects an unknown flow" do
    oauth_session = LineOauthSession.new(session: {})

    assert_raises(ArgumentError) { oauth_session.start(flow: "unknown") }
  end
end
