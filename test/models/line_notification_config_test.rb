require "test_helper"

class LineNotificationConfigTest < ActiveSupport::TestCase
  test "is enabled by default outside production" do
    with_line_notification_enabled(nil) do
      assert_predicate LineNotificationConfig, :enabled?
    end
  end

  test "is enabled when the environment variable is true" do
    with_line_notification_enabled("true") do
      assert_predicate LineNotificationConfig, :enabled?
    end
  end

  test "is disabled when the environment variable is false" do
    with_line_notification_enabled("false") do
      assert_not_predicate LineNotificationConfig, :enabled?
    end
  end

  private

  def with_line_notification_enabled(value)
    original_value = ENV["LINE_NOTIFICATION_ENABLED"]

    if value.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = value
    end

    yield
  ensure
    if original_value.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = original_value
    end
  end
end
