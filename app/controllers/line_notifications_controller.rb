class LineNotificationsController < ApplicationController
  before_action :require_login

  def create
    line_connection = current_user.line_connection

    unless line_connection&.linked?
      redirect_to profile_path, alert: t(".not_connected"), status: :see_other
      return
    end

    LineNotificationSender.call(
      line_connection:,
      message: t(".test_message", name: current_user.name)
    )
    redirect_to profile_path, notice: t(".success"), status: :see_other
  rescue LineNotificationSender::ConfigurationError => error
    Rails.logger.error("LINE notification configuration error: #{error.message}")
    redirect_to profile_path, alert: t(".configuration_error"), status: :see_other
  rescue LineNotificationSender::DeliveryError => error
    Rails.logger.error("LINE notification delivery error: #{error.message}")
    redirect_to profile_path, alert: t(".delivery_error"), status: :see_other
  end
end
