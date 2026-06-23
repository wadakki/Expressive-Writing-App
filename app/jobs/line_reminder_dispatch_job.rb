class LineReminderDispatchJob < ApplicationJob
  queue_as :default

  def perform(scheduled_at = Time.current.iso8601)
    scheduled_time = Time.zone.parse(scheduled_at).beginning_of_minute

    NotificationSetting.where(notification_enabled: true).includes(user: :line_connection).find_each do |setting|
      enqueue_reminder(setting, scheduled_time)
    end
  end

  private

  def enqueue_reminder(setting, scheduled_time)
    return unless setting.due_for_reminder?(scheduled_time)
    return unless setting.user.line_connection&.linked?

    job = LineReminderNotificationJob.perform_later(setting.id, scheduled_time.iso8601)
    raise ActiveJob::EnqueueError, "LINE reminder was not enqueued" unless job&.successfully_enqueued?
  rescue ActiveJob::EnqueueError, RedisClient::Error => error
    Rails.logger.error(
      "LINE reminder enqueue error: notification_setting_id=#{setting.id} error=#{error.class}"
    )
  end
end
