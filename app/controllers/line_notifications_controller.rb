class LineNotificationsController < ApplicationController
  before_action :require_login
  before_action :ensure_line_notifications_enabled

  def create
    line_connection = current_user.line_connection

    unless line_connection&.linked?
      redirect_to profile_path, alert: t(".not_connected"), status: :see_other
      return
    end

    job = LineNotificationJob.perform_later(
      line_connection.id,
      t(".test_message", name: current_user.name)
    )
    raise ActiveJob::EnqueueError, "LINE notification was not enqueued" unless job&.successfully_enqueued?

    redirect_to profile_path, notice: t(".success"), status: :see_other
  rescue ActiveJob::EnqueueError, RedisClient::Error => error
    Rails.logger.error("LINE notification enqueue error: #{error.class}")
    redirect_to profile_path, alert: t(".enqueue_error"), status: :see_other
  end

  private

  def ensure_line_notifications_enabled
    return if LineNotificationConfig.enabled?

    redirect_to profile_path, alert: t(".disabled"), status: :see_other
  end
end
