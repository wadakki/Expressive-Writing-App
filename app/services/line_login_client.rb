require "json"
require "net/http"
require "uri"

class LineLoginClient
  AUTHORIZATION_ENDPOINT = "https://access.line.me/oauth2/v2.1/authorize"
  TOKEN_ENDPOINT = "https://api.line.me/oauth2/v2.1/token"
  VERIFY_ENDPOINT = "https://api.line.me/oauth2/v2.1/verify"

  class Error < StandardError; end
  class ConfigurationError < Error; end
  class AuthenticationError < Error; end

  def initialize(channel_id: ENV["LINE_LOGIN_CHANNEL_ID"],
                 channel_secret: ENV["LINE_LOGIN_CHANNEL_SECRET"],
                 redirect_uri: ENV["LINE_LOGIN_REDIRECT_URI"], requester: nil)
    @channel_id = channel_id
    @channel_secret = channel_secret
    @redirect_uri = redirect_uri
    @requester = requester || method(:perform_post)
  end

  def authorization_url(state:, nonce:, bot_prompt: "aggressive")
    validate_configuration!
    uri = URI(AUTHORIZATION_ENDPOINT)
    params = {
      response_type: "code",
      client_id: channel_id,
      redirect_uri:,
      state:,
      scope: "profile openid",
      nonce:
    }
    params[:bot_prompt] = bot_prompt if bot_prompt.present?
    uri.query = URI.encode_www_form(params)
    uri.to_s
  end

  def user_id(code:, nonce:)
    validate_configuration!
    raise AuthenticationError, "Authorization code is missing" if code.blank?

    token = post_form(
      TOKEN_ENDPOINT,
      grant_type: "authorization_code",
      code:,
      redirect_uri:,
      client_id: channel_id,
      client_secret: channel_secret
    )
    id_token = token["id_token"]
    raise AuthenticationError, "ID token is missing" if id_token.blank?

    verification = post_form(VERIFY_ENDPOINT, id_token:, client_id: channel_id)
    validate_nonce!(verification["nonce"], nonce)

    verification["sub"].presence || raise(AuthenticationError, "LINE user ID is missing")
  end

  private

  attr_reader :channel_id, :channel_secret, :redirect_uri, :requester

  def validate_configuration!
    values = [ channel_id, channel_secret, redirect_uri ]
    return if values.all?(&:present?)

    raise ConfigurationError, "LINE Login environment variables are not configured"
  end

  def validate_nonce!(actual_nonce, expected_nonce)
    actual = actual_nonce.to_s
    expected = expected_nonce.to_s
    valid = actual.bytesize == expected.bytesize && actual.present? &&
            ActiveSupport::SecurityUtils.secure_compare(actual, expected)
    return if valid

    raise AuthenticationError, "ID token nonce is invalid"
  end

  def post_form(endpoint, params)
    status, body = requester.call(URI(endpoint), params)
    payload = JSON.parse(body)
    return payload if status.to_i.between?(200, 299)

    raise AuthenticationError, "LINE Login request failed"
  rescue JSON::ParserError
    raise AuthenticationError, "LINE Login response is invalid"
  end

  def perform_post(uri, params)
    request = Net::HTTP::Post.new(uri)
    request.set_form_data(params)
    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: true,
      open_timeout: 5,
      read_timeout: 10
    ) { |http| http.request(request) }
    [ response.code.to_i, response.body ]
  rescue Timeout::Error, SocketError, SystemCallError => error
    raise AuthenticationError, "LINE Login request failed", cause: error
  end
end
