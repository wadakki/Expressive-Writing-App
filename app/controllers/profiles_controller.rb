class ProfilesController < ApplicationController
  before_action :require_login
  before_action :set_user
  before_action :set_notification_setting
  before_action :set_line_connection
  before_action :set_line_notification_config

  def show
    @notification_setting ||= build_default_notification_setting
  end

  def update
    @notification_setting ||= build_default_notification_setting
    assign_update_attributes

    if valid_update_attributes?
      save_profile!
      redirect_to profile_path, notice: t(".success")
    else
      render :show, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = current_user
  end

  def set_notification_setting
    @notification_setting = current_user.notification_setting
  end

  def set_line_connection
    @line_connection = current_user.line_connection
  end

  def set_line_notification_config
    @line_notifications_enabled = LineNotificationConfig.enabled?
  end

  def build_default_notification_setting
    current_user.build_notification_setting(
      notification_enabled: false,
      notification_time: "21:00",
      reminder_days: NotificationSetting::VALID_REMINDER_DAYS
    )
  end

  def assign_update_attributes
    @user.assign_attributes(profile_params)
    @notification_setting.assign_attributes(notification_setting_params)
  end

  def valid_update_attributes?
    user_valid = @user.valid?
    notification_setting_valid = @notification_setting.valid?

    user_valid && notification_setting_valid
  end

  def save_profile!
    ActiveRecord::Base.transaction do
      @user.save!
      @notification_setting.save!
    end
  end

  def profile_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation)
  end

  def notification_setting_params
    params.fetch(:notification_setting, ActionController::Parameters.new).permit(
      :notification_enabled,
      :notification_time,
      reminder_days: []
    )
  end
end
