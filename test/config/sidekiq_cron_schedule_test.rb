require "test_helper"
require "erb"
require "yaml"

class SidekiqCronScheduleTest < ActiveSupport::TestCase
  test "defines a valid minutely Tokyo reminder dispatch schedule" do
    schedule_path = Rails.root.join("config/schedule.yml")
    schedule = YAML.safe_load(ERB.new(schedule_path.read).result)
    reminder = schedule.fetch("line_reminder_dispatch")

    assert_equal "LineReminderDispatchJob", reminder.fetch("class")
    assert_equal "default", reminder.fetch("queue")
    assert_equal true, reminder.fetch("active_job")
    assert_equal "* * * * * Asia/Tokyo", reminder.fetch("cron")
    assert Fugit::Cron.parse(reminder.fetch("cron"))
    assert_operator LineReminderDispatchJob, :<, ApplicationJob
  end
end
