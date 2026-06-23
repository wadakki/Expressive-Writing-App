class LineReminderNotificationJob < ApplicationJob
  queue_as :default

  def perform(notification_setting_id, scheduled_at)
    notification_setting = NotificationSetting.find_by(id: notification_setting_id)
    return unless notification_setting

    deliver_with_lock(notification_setting, Time.zone.parse(scheduled_at).beginning_of_minute)
  rescue StandardError => error
    Rails.logger.error(
      "LINE reminder delivery error: notification_setting_id=#{notification_setting_id} error=#{error.class}"
    )
    raise
  end

  private

  def deliver_with_lock(notification_setting, scheduled_time)
    notification_setting.with_lock do
      notification_setting.reload
      return unless notification_setting.due_for_reminder?(scheduled_time)

      line_connection = notification_setting.user.line_connection
      return unless line_connection&.linked?

      LineNotificationSender.call(
        line_connection:,
        message: reminder_message(notification_setting.user)
      )
      notification_setting.update!(last_reminded_at: Time.current)
    end
  end

  def reminder_message(user)
    I18n.t(
      "line_reminders.message",
      name: user.name,
      url: Rails.application.routes.url_helpers.new_writing_entry_url(url_options)
    )
  end

  def url_options
    Rails.application.config.action_mailer.default_url_options.presence || fallback_url_options
  end

  def fallback_url_options
    {
      host: ENV.fetch("APP_HOST", "localhost"),
      port: ENV["APP_PORT"],
      protocol: ENV.fetch("APP_PROTOCOL", Rails.env.production? ? "https" : "http")
    }.compact
  end
end
