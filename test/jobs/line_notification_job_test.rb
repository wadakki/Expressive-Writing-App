require "test_helper"
require "minitest/mock"

class LineNotificationJobTest < ActiveJob::TestCase
  setup do
    user = User.create!(
      name: "LINEジョブユーザー",
      email: "line-job@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @line_connection = user.create_line_connection!(
      line_user_id: "line-job-user-123",
      status: :linked
    )
  end

  test "sends a notification through the sender" do
    sender = lambda do |line_connection: nil, message: nil|
      assert_equal @line_connection, line_connection
      assert_equal "ジョブ通知", message
      true
    end

    LineNotificationSender.stub(:call, sender) do
      LineNotificationJob.perform_now(@line_connection.id, "ジョブ通知")
    end
  end

  test "does nothing when the line connection was deleted" do
    connection_id = @line_connection.id
    @line_connection.destroy!

    LineNotificationSender.stub(:call, ->(**) { flunk("sender should not be called") }) do
      assert_nil LineNotificationJob.perform_now(connection_id, "ジョブ通知")
    end
  end

  test "does nothing when the line connection is blocked" do
    @line_connection.blocked!

    LineNotificationSender.stub(:call, ->(**) { flunk("sender should not be called") }) do
      assert_nil LineNotificationJob.perform_now(@line_connection.id, "ジョブ通知")
    end
  end

  test "lets delivery errors propagate for Sidekiq retries" do
    error = LineNotificationSender::DeliveryError.new("LINE API failure")

    LineNotificationSender.stub(:call, ->(**) { raise error }) do
      assert_raises(LineNotificationSender::DeliveryError) do
        LineNotificationJob.perform_now(@line_connection.id, "ジョブ通知")
      end
    end
  end
end
