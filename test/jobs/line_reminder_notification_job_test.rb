require "test_helper"
require "minitest/mock"

class LineReminderNotificationJobTest < ActiveJob::TestCase
  setup do
    @original_line_notification_enabled = ENV["LINE_NOTIFICATION_ENABLED"]
    ENV["LINE_NOTIFICATION_ENABLED"] = "true"

    user = User.create!(
      name: "リマインダー送信ユーザー",
      email: "reminder-delivery@example.com",
      password: "password",
      password_confirmation: "password"
    )
    @line_connection = user.create_line_connection!(
      line_user_id: "line-reminder-user",
      status: :linked
    )
    @notification_setting = user.create_notification_setting!(
      notification_enabled: true,
      notification_time: "21:00",
      reminder_days: [ 1 ]
    )
    @scheduled_time = Time.zone.local(2026, 6, 22, 21, 0)
  end

  teardown do
    restore_line_notification_enabled
  end

  test "sends a reminder and records the successful delivery time" do
    delivered_at = @scheduled_time + 15.seconds
    sender = lambda do |line_connection: nil, message: nil|
      assert_equal @line_connection, line_connection
      assert_match(/筆記開示を書く時間となりました。今日の気持ちを整理してみませんか？/, message)
      assert_match(%r{http://www.example.com/writing_entries/new}, message)
      true
    end

    travel_to delivered_at do
      LineNotificationSender.stub(:call, sender) do
        LineReminderNotificationJob.perform_now(@notification_setting.id, @scheduled_time.iso8601)
      end
    end

    assert_equal delivered_at, @notification_setting.reload.last_reminded_at
  end

  test "does not deliver when LINE notifications are disabled" do
    ENV["LINE_NOTIFICATION_ENABLED"] = "false"

    LineNotificationSender.stub(:call, ->(**) { flunk("sender should not be called") }) do
      assert_nil LineReminderNotificationJob.perform_now(
        @notification_setting.id,
        @scheduled_time.iso8601
      )
    end
    assert_nil @notification_setting.reload.last_reminded_at
  end

  test "does not deliver the same scheduled reminder twice" do
    deliveries = 0
    sender = lambda do |**|
      deliveries += 1
      true
    end

    LineNotificationSender.stub(:call, sender) do
      2.times do
        LineReminderNotificationJob.perform_now(@notification_setting.id, @scheduled_time.iso8601)
      end
    end

    assert_equal 1, deliveries
  end

  test "rechecks settings and connection state before delivery" do
    @notification_setting.update!(notification_enabled: false)

    LineNotificationSender.stub(:call, ->(**) { flunk("sender should not be called") }) do
      assert_nil LineReminderNotificationJob.perform_now(
        @notification_setting.id,
        @scheduled_time.iso8601
      )
    end
    assert_nil @notification_setting.reload.last_reminded_at
  end

  test "does not deliver when the LINE connection was blocked after enqueueing" do
    @line_connection.blocked!

    LineNotificationSender.stub(:call, ->(**) { flunk("sender should not be called") }) do
      assert_nil LineReminderNotificationJob.perform_now(
        @notification_setting.id,
        @scheduled_time.iso8601
      )
    end
    assert_nil @notification_setting.reload.last_reminded_at
  end

  test "propagates delivery failures and does not mark the reminder" do
    error = LineNotificationSender::DeliveryError.new("LINE API failure")

    LineNotificationSender.stub(:call, ->(**) { raise error }) do
      assert_raises(LineNotificationSender::DeliveryError) do
        LineReminderNotificationJob.perform_now(@notification_setting.id, @scheduled_time.iso8601)
      end
    end

    assert_nil @notification_setting.reload.last_reminded_at
  end

  private

  def restore_line_notification_enabled
    if @original_line_notification_enabled.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = @original_line_notification_enabled
    end
  end
end
