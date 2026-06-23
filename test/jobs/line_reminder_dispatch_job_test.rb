require "test_helper"
require "minitest/mock"

class LineReminderDispatchJobTest < ActiveJob::TestCase
  include ActiveJob::TestHelper

  setup do
    @original_line_notification_enabled = ENV["LINE_NOTIFICATION_ENABLED"]
    ENV["LINE_NOTIFICATION_ENABLED"] = "true"

    clear_enqueued_jobs
    @scheduled_time = Time.zone.local(2026, 6, 22, 21, 0)
  end

  teardown do
    restore_line_notification_enabled
  end

  test "enqueues a reminder for an enabled due and linked user" do
    setting = create_setting(email: "due@example.com")

    assert_enqueued_with(
      job: LineReminderNotificationJob,
      args: [ setting.id, @scheduled_time.iso8601 ]
    ) do
      LineReminderDispatchJob.perform_now(@scheduled_time.iso8601)
    end
  end

  test "does not enqueue reminders when LINE notifications are disabled" do
    ENV["LINE_NOTIFICATION_ENABLED"] = "false"
    create_setting(email: "disabled-line-notification@example.com")

    assert_no_enqueued_jobs do
      LineReminderDispatchJob.perform_now(@scheduled_time.iso8601)
    end
  end

  test "does not enqueue for disabled wrong day wrong time or blocked settings" do
    create_setting(email: "disabled@example.com", notification_enabled: false)
    create_setting(email: "wrong-day@example.com", reminder_days: [ 2 ])
    create_setting(email: "wrong-time@example.com", notification_time: "20:59")
    create_setting(email: "blocked@example.com", line_status: :blocked)

    assert_no_enqueued_jobs do
      LineReminderDispatchJob.perform_now(@scheduled_time.iso8601)
    end
  end

  test "continues enqueueing other users when one enqueue fails" do
    create_setting(email: "enqueue-error@example.com")
    create_setting(email: "enqueue-success@example.com")
    calls = 0
    enqueued_job = Struct.new(:successfully_enqueued?).new(true)
    enqueue = lambda do |*_args|
      calls += 1
      raise ActiveJob::EnqueueError, "Redis unavailable" if calls == 1

      enqueued_job
    end

    LineReminderNotificationJob.stub(:perform_later, enqueue) do
      assert_nothing_raised { LineReminderDispatchJob.perform_now(@scheduled_time.iso8601) }
    end

    assert_equal 2, calls
  end

  private

  def restore_line_notification_enabled
    if @original_line_notification_enabled.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = @original_line_notification_enabled
    end
  end

  def create_setting(email:, notification_enabled: true, notification_time: "21:00",
                     reminder_days: [ 1 ], line_status: :linked)
    user = User.create!(
      name: "リマインダー対象ユーザー",
      email:,
      password: "password",
      password_confirmation: "password"
    )
    user.create_line_connection!(line_user_id: "line-#{email}", status: line_status)
    user.create_notification_setting!(
      notification_enabled:,
      notification_time:,
      reminder_days:
    )
  end
end
