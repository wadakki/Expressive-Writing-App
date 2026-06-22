require "test_helper"
require "minitest/mock"

class LineNotificationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "LINE通知ユーザー",
      email: "line-notification@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "sends a test notification for a linked user" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)
    sender = lambda do |line_connection: nil, message: nil|
      assert_equal @user.line_connection, line_connection
      assert_match(/LINE通知テスト/, message)
      true
    end

    LineNotificationSender.stub(:call, sender) { post line_notification_url }

    assert_redirected_to profile_url
    assert_equal "LINEへテスト通知を送信しました", flash[:notice]
  end

  test "does not send when LINE is not connected" do
    login_as(@user)

    LineNotificationSender.stub(:call, -> { flunk("sender should not be called") }) do
      post line_notification_url
    end

    assert_redirected_to profile_url
    assert_equal "LINE連携が完了していないため通知を送信できません", flash[:alert]
  end

  test "shows a configuration error" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)
    error = LineNotificationSender::ConfigurationError.new("missing token")

    LineNotificationSender.stub(:call, ->(**) { raise error }) { post line_notification_url }

    assert_redirected_to profile_url
    assert_equal "LINEチャネルアクセストークンが設定されていません", flash[:alert]
  end

  test "shows a delivery error" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)
    error = LineNotificationSender::DeliveryError.new("API failure")

    LineNotificationSender.stub(:call, ->(**) { raise error }) { post line_notification_url }

    assert_redirected_to profile_url
    assert_equal "LINE通知を送信できませんでした。時間をおいて再度お試しください", flash[:alert]
  end

  test "redirects guests to login" do
    post line_notification_url

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  private

  def login_as(user)
    post login_url, params: {
      user_session: { email: user.email, password: "password" }
    }
  end
end
