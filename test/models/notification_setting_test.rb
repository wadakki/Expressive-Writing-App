require "test_helper"

class NotificationSettingTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "通知ユーザー",
      email: "notification@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "is valid with a user notification flag and notification time" do
    notification_setting = build_notification_setting

    assert notification_setting.valid?
  end

  test "belongs to a user" do
    notification_setting = build_notification_setting
    notification_setting.save!

    assert_equal @user, notification_setting.user
    assert_equal notification_setting, @user.notification_setting
  end

  test "destroys notification setting when the user is destroyed" do
    notification_setting = build_notification_setting
    notification_setting.save!

    assert_difference("NotificationSetting.count", -1) do
      @user.destroy!
    end
    assert_not NotificationSetting.exists?(notification_setting.id)
  end

  test "requires a user" do
    notification_setting = build_notification_setting(user: nil)

    assert_not notification_setting.valid?
    assert_includes notification_setting.errors[:user], "を入力してください"
  end

  test "allows one notification setting per user" do
    build_notification_setting.save!
    duplicate_setting = build_notification_setting

    assert_not duplicate_setting.valid?
    assert_includes duplicate_setting.errors[:user_id], "はすでに存在します"
  end

  test "requires notification enabled to be true or false" do
    notification_setting = build_notification_setting(notification_enabled: nil)

    assert_not notification_setting.valid?
    assert_includes notification_setting.errors[:notification_enabled], "は一覧にありません"
  end

  test "accepts notification enabled as true" do
    notification_setting = build_notification_setting(notification_enabled: true)

    assert notification_setting.valid?
  end

  test "accepts notification enabled as false" do
    notification_setting = build_notification_setting(notification_enabled: false)

    assert notification_setting.valid?
  end

  test "requires a notification time" do
    notification_setting = build_notification_setting(notification_time: nil)

    assert_not notification_setting.valid?
    assert_includes notification_setting.errors[:notification_time], "を入力してください"
  end

  private

  def build_notification_setting(user: @user, notification_enabled: false,
                                 notification_time: "21:00")
    NotificationSetting.new(
      user:,
      notification_enabled:,
      notification_time:
    )
  end
end
