class LineNotificationSender
  class Error < StandardError; end
  class ConfigurationError < Error; end
  class DeliveryError < Error; end

  def self.call(...)
    new(...).call
  end

  def initialize(line_connection:, message:, client: nil,
                 channel_access_token: ENV["LINE_CHANNEL_ACCESS_TOKEN"])
    @line_connection = line_connection
    @message = message
    @client = client
    @channel_access_token = channel_access_token
  end

  def call
    validate_delivery!
    _body, status_code, _headers = client.push_message_with_http_info(
      push_message_request:
    )
    ensure_successful_response!(status_code)
    line_connection.update!(last_notified_at: Time.current)
    true
  rescue ConfigurationError, DeliveryError
    raise
  rescue StandardError => error
    raise DeliveryError, error.message
  end

  private

  attr_reader :line_connection, :message, :channel_access_token

  def client
    @client ||= Line::Bot::V2::MessagingApi::ApiClient.new(
      channel_access_token: channel_access_token!
    )
  end

  def channel_access_token!
    return channel_access_token if channel_access_token.present?

    raise ConfigurationError, "LINE_CHANNEL_ACCESS_TOKEN is not configured"
  end

  def validate_delivery!
    raise DeliveryError, "LINE connection is not linked" unless line_connection&.linked?
    raise DeliveryError, "Message must be present" if message.blank?
  end

  def push_message_request
    Line::Bot::V2::MessagingApi::PushMessageRequest.new(
      to: line_connection.line_user_id,
      messages: [ Line::Bot::V2::MessagingApi::TextMessage.new(text: message) ]
    )
  end

  def ensure_successful_response!(status_code)
    return if status_code.to_i.between?(200, 299)

    raise DeliveryError, "LINE Messaging API returned status #{status_code}"
  end
end
