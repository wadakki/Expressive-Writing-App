require "test_helper"

class LineNotificationSenderTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :request

    def initialize(status_code: 200)
      @status_code = status_code
    end

    def push_message_with_http_info(push_message_request:)
      @request = push_message_request
      [ nil, @status_code, {} ]
    end
  end

  setup do
    user = User.create!(
      name: "LINE送信ユーザー",
      email: "line-sender@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @line_connection = user.create_line_connection!(
      line_user_id: "line-user-123",
      status: :linked
    )
  end

  test "sends a text message and updates last notified at" do
    client = FakeClient.new
    notified_at = Time.zone.local(2026, 6, 19, 21, 0)

    travel_to notified_at do
      assert LineNotificationSender.call(
        line_connection: @line_connection,
        message: "通知テスト",
        client:
      )
    end

    assert_equal "line-user-123", client.request.to
    assert_equal "通知テスト", client.request.messages.first.text
    assert_equal notified_at, @line_connection.reload.last_notified_at
  end

  test "raises a configuration error when token is missing" do
    error = assert_raises(LineNotificationSender::ConfigurationError) do
      LineNotificationSender.call(
        line_connection: @line_connection,
        message: "通知テスト",
        channel_access_token: ""
      )
    end

    assert_match(/LINE_CHANNEL_ACCESS_TOKEN/, error.message)
  end

  test "does not send when connection is blocked" do
    @line_connection.blocked!
    client = FakeClient.new

    assert_raises(LineNotificationSender::DeliveryError) do
      LineNotificationSender.call(line_connection: @line_connection, message: "通知テスト", client:)
    end

    assert_nil client.request
    assert_nil @line_connection.reload.last_notified_at
  end

  test "does not update last notified at when API returns an error" do
    client = FakeClient.new(status_code: 400)

    assert_raises(LineNotificationSender::DeliveryError) do
      LineNotificationSender.call(line_connection: @line_connection, message: "通知テスト", client:)
    end

    assert_nil @line_connection.reload.last_notified_at
  end
end
