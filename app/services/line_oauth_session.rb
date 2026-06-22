require "securerandom"

class LineOauthSession
  SESSION_KEY = :line_oauth
  LINK_FLOW = "link"
  LOGIN_FLOW = "login"
  VALID_FLOWS = [ LINK_FLOW, LOGIN_FLOW ].freeze

  class InvalidStateError < StandardError; end

  def initialize(session:)
    @session = session
  end

  def start(flow:)
    normalized_flow = flow.to_s
    raise ArgumentError, "Unknown LINE OAuth flow" unless VALID_FLOWS.include?(normalized_flow)

    payload = {
      "flow" => normalized_flow,
      "state" => SecureRandom.urlsafe_base64(32),
      "nonce" => SecureRandom.urlsafe_base64(32)
    }
    session[SESSION_KEY] = payload

    { flow: payload["flow"], state: payload["state"], nonce: payload["nonce"] }
  end

  def flow
    session[SESSION_KEY]&.fetch("flow", nil)
  end

  def consume!(state:)
    payload = session.delete(SESSION_KEY) || {}
    raise InvalidStateError unless valid_payload?(payload, state)

    { flow: payload["flow"], nonce: payload["nonce"] }
  end

  def clear
    session.delete(SESSION_KEY)
  end

  private

  attr_reader :session

  def valid_payload?(payload, actual_state)
    expected_state = payload["state"].to_s
    actual = actual_state.to_s

    VALID_FLOWS.include?(payload["flow"]) && payload["nonce"].present? &&
      expected_state.present? && expected_state.bytesize == actual.bytesize &&
      ActiveSupport::SecurityUtils.secure_compare(expected_state, actual)
  end
end
