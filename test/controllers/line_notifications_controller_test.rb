require "test_helper"
require "minitest/mock"

class LineNotificationsControllerTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  setup do
    @original_line_notification_enabled = ENV["LINE_NOTIFICATION_ENABLED"]
    ENV["LINE_NOTIFICATION_ENABLED"] = "true"
    clear_enqueued_jobs
    @user = User.create!(
      name: "LINE通知ユーザー",
      email: "line-notification@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  teardown do
    if @original_line_notification_enabled.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = @original_line_notification_enabled
    end
  end

  test "enqueues a test notification for a linked user" do
    line_connection = @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)

    assert_enqueued_with(job: LineNotificationJob) do
      post line_notification_url
    end

    assert_redirected_to profile_url
    assert_equal "LINEテスト通知を受け付けました。送信まで少しお待ちください", flash[:notice]
    enqueued_job = enqueued_jobs.last
    assert_equal line_connection.id, enqueued_job.fetch(:args).first
    assert_match(/LINE通知テスト/, enqueued_job.fetch(:args).second)
  end

  test "does not enqueue when LINE notifications are disabled" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)

    with_line_notification_enabled("false") do
      assert_no_enqueued_jobs do
        post line_notification_url
      end
    end

    assert_redirected_to profile_url
    assert_equal "現在、無料Render構成のためLINE通知は停止中です。有料Worker設定後に通知とリマインダー送信を利用できます。", flash[:alert]
  end

  test "does not send when LINE is not connected" do
    login_as(@user)

    assert_no_enqueued_jobs do
      post line_notification_url
    end

    assert_redirected_to profile_url
    assert_equal "LINE連携が完了していないため通知を送信できません", flash[:alert]
  end

  test "shows an error when enqueueing fails" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)
    error = ActiveJob::EnqueueError.new("Redis unavailable")

    LineNotificationJob.stub(:perform_later, ->(*) { raise error }) { post line_notification_url }

    assert_redirected_to profile_url
    assert_equal "LINE通知を受け付けられませんでした。時間をおいて再度お試しください", flash[:alert]
  end

  test "shows an error when the job reports that it was not enqueued" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)
    failed_job = Struct.new(:successfully_enqueued?).new(false)

    LineNotificationJob.stub(:perform_later, failed_job) { post line_notification_url }

    assert_redirected_to profile_url
    assert_equal "LINE通知を受け付けられませんでした。時間をおいて再度お試しください", flash[:alert]
  end

  test "redirects guests to login" do
    post line_notification_url

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  private

  def with_line_notification_enabled(value)
    original_value = ENV["LINE_NOTIFICATION_ENABLED"]
    ENV["LINE_NOTIFICATION_ENABLED"] = value
    yield
  ensure
    if original_value.nil?
      ENV.delete("LINE_NOTIFICATION_ENABLED")
    else
      ENV["LINE_NOTIFICATION_ENABLED"] = original_value
    end
  end

  def login_as(user)
    post login_url, params: {
      user_session: { email: user.email, password: "password" }
    }
  end
end
