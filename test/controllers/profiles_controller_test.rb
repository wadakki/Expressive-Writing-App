require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @original_line_notification_enabled = ENV["LINE_NOTIFICATION_ENABLED"]
    ENV["LINE_NOTIFICATION_ENABLED"] = "true"
    @user = User.create!(
      name: "プロフィールユーザー",
      email: "profile@example.com",
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

  test "redirects guests to login" do
    get profile_url

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  test "shows the current user's profile" do
    login_as(@user)

    get profile_url

    assert_response :success
    assert_select "h1", "プロフィール"
    assert_select "h2", "プロフィールユーザー"
    assert_select "form[action=?][method=post]", profile_path, count: 1
    assert_select "input[name=?][value=?]", "user[name]", "プロフィールユーザー"
    assert_select "input[name=?][value=?]", "user[email]", "profile@example.com"
    assert_select "input[type=password][name=?][value=?][disabled]", "masked_password", "********"
    assert_select "input[type=password][name=?]", "user[password]"
    assert_select "input[type=password][name=?]", "user[password_confirmation]"
    assert_select "input[type=submit][value=?]", "更新する", count: 1
    assert_select "h2", "通知設定"
    assert_select "input[name=?][type=hidden][value=0]", "notification_setting[notification_enabled]"
    assert_select "input[name=?][type=checkbox]", "notification_setting[notification_enabled]"
    assert_select "input[name=?][type=time][value='21:00'][required]",
                  "notification_setting[notification_time]"
    assert_select "input[type=checkbox][name=?]",
                  "notification_setting[reminder_days][]", count: 7
    assert_select "input[type=checkbox][name=?][checked=checked]",
                  "notification_setting[reminder_days][]", count: 7
    assert_select "h2", "LINE連携状況"
    assert_select "span", "未連携"
    assert_select "form[action=?]", line_notification_path, count: 0
    assert_select "a[href=?]", new_line_connection_path, text: "LINE連携する"
    assert_select "form[action=?]", line_connection_path, count: 0
  end

  test "shows that LINE notifications are disabled when configured off" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)

    with_line_notification_enabled("false") do
      get profile_url
    end

    assert_response :success
    assert_select "span", "連携済み"
    assert_select "[role=status]", text: /LINE通知は停止中です/
    assert_select "[role=status]", text: /無料Render構成のためLINE通知は停止中です/
    assert_select "form[action=?][method=post]", line_notification_path, count: 0
    assert_select "button[type=submit]", text: "テスト通知を送信する", count: 0
    assert_select "form[action=?]", line_connection_path
  end

  test "shows LINE notification button for a linked user" do
    @user.create_line_connection!(line_user_id: "line-user-123", status: :linked)
    login_as(@user)

    get profile_url

    assert_response :success
    assert_select "span", "連携済み"
    assert_select "form[action=?][method=post]", line_notification_path
    assert_select "button[type=submit]", "テスト通知を送信する"
    assert_select "a[href=?]", new_line_connection_path, count: 0
    assert_select "form[action=?]", line_connection_path
  end

  test "updates the current user's profile and creates notification setting" do
    login_as(@user)

    assert_difference("NotificationSetting.count", 1) do
      patch profile_url, params: {
        user: {
          name: "更新ユーザー",
          email: "updated-profile@example.com",
          password: "",
          password_confirmation: ""
        },
        notification_setting: {
          notification_enabled: "1",
          notification_time: "08:15",
          reminder_days: %w[1 3 5]
        }
      }
    end

    assert_redirected_to profile_url
    assert_equal "プロフィールを更新しました", flash[:notice]
    @user.reload
    assert_equal "更新ユーザー", @user.name
    assert_equal "updated-profile@example.com", @user.email
    assert_predicate @user.notification_setting, :notification_enabled?
    assert_equal "08:15", @user.notification_setting.notification_time.strftime("%H:%M")
    assert_equal [ 1, 3, 5 ], @user.notification_setting.reminder_days
  end

  test "updates the current user's password" do
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: @user.name,
        email: @user.email,
        password: "new-password",
        password_confirmation: "new-password"
      },
      notification_setting: {
        notification_enabled: "0",
        notification_time: "21:00"
      }
    }

    assert_redirected_to profile_url
    delete logout_url

    post login_url, params: {
      user_session: {
        email: @user.email,
        password: "new-password"
      }
    }

    assert_redirected_to root_url
  end

  test "renders errors when profile update is invalid" do
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: "",
        email: "invalid-email",
        password: "short",
        password_confirmation: "different"
      },
      notification_setting: {
        notification_enabled: "1",
        notification_time: "21:00"
      }
    }

    assert_response :unprocessable_entity
    assert_select "#profile-update-error[role=alert]", text: /更新できませんでした/
    assert_select "[role=alert]", text: /入力内容を確認してください/
    assert_select "[role=alert]", text: /名前を入力してください/
    assert_select "[role=alert]", text: /メールアドレスは不正な値です/
    assert_select "[role=alert]", text: /パスワードは8文字以上で入力してください/
    assert_select "input[name=?][value=?]", "user[email]", "invalid-email"
  end

  test "shows the current user's existing notification setting" do
    @user.create_notification_setting!(
      notification_enabled: true,
      notification_time: "07:30",
      reminder_days: [ 1, 3, 5 ]
    )
    login_as(@user)

    get profile_url

    assert_response :success
    assert_select "h2", "通知設定"
    assert_select "input[name=?][type=checkbox][checked=checked]", "notification_setting[notification_enabled]"
    assert_select "input[name=?][type=time][value='07:30']",
                  "notification_setting[notification_time]"
    %w[1 3 5].each do |day|
      assert_select "input[type=checkbox][name=?][value=?][checked=checked]",
                    "notification_setting[reminder_days][]", day
    end
  end

  test "updates the current user's existing notification setting through profile" do
    notification_setting = @user.create_notification_setting!(
      notification_enabled: true,
      notification_time: "07:30",
      reminder_days: [ 1, 3, 5 ]
    )
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: @user.name,
        email: @user.email,
        password: "",
        password_confirmation: ""
      },
      notification_setting: {
        notification_enabled: "0",
        notification_time: "22:45",
        reminder_days: %w[0 6]
      }
    }

    assert_redirected_to profile_url
    assert_equal "プロフィールを更新しました", flash[:notice]
    notification_setting.reload
    assert_not_predicate notification_setting, :notification_enabled?
    assert_equal "22:45", notification_setting.notification_time.strftime("%H:%M")
    assert_equal [ 0, 6 ], notification_setting.reminder_days
  end

  test "renders errors when reminder days are invalid" do
    login_as(@user)

    assert_no_difference("NotificationSetting.count") do
      patch profile_url, params: {
        user: {
          name: "曜日エラー",
          email: @user.email,
          password: "",
          password_confirmation: ""
        },
        notification_setting: {
          notification_enabled: "1",
          notification_time: "21:00",
          reminder_days: [ "7" ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "#profile-update-error[role=alert]", text: /更新できませんでした/
    assert_select "[role=alert]", text: /通知設定は保存されていません/
    assert_select "[role=alert]", text: /通知曜日は一覧にありません/
    assert_select "fieldset[aria-invalid=true]", text: /通知曜日は一覧にありません/
    assert_equal "プロフィールユーザー", @user.reload.name
  end

  test "clearly shows errors when notification is enabled without reminder days" do
    login_as(@user)

    assert_no_difference("NotificationSetting.count") do
      patch profile_url, params: {
        user: {
          name: "曜日未選択",
          email: @user.email,
          password: "",
          password_confirmation: ""
        },
        notification_setting: {
          notification_enabled: "1",
          notification_time: "21:00",
          reminder_days: [ "" ]
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "#profile-update-error[role=alert]", text: /更新できませんでした/
    assert_select "#profile-update-error", text: /変更内容は保存されていません/
    assert_select "[role=alert]", text: /通知設定は保存されていません/
    assert_select "fieldset[aria-invalid=true]", text: /通知曜日を入力してください/
    assert_equal "プロフィールユーザー", @user.reload.name
  end

  test "renders errors when notification setting is invalid" do
    login_as(@user)

    assert_no_difference("NotificationSetting.count") do
      patch profile_url, params: {
        user: {
          name: "通知設定エラー",
          email: @user.email,
          password: "",
          password_confirmation: ""
        },
        notification_setting: {
          notification_enabled: "1",
          notification_time: ""
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /通知設定は保存されていません/
    assert_select "[role=alert]", text: /通知時刻を入力してください/
    assert_equal "プロフィールユーザー", @user.reload.name
  end

  test "does not allow guests to update a profile" do
    patch profile_url, params: {
      user: {
        name: "未ログイン更新",
        email: "guest-update@example.com"
      }
    }

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
    assert_not_equal "未ログイン更新", @user.reload.name
  end

  test "does not update another user's profile" do
    other_user = User.create!(
      name: "別ユーザー",
      email: "other-profile@example.com",
      password: "password",
      password_confirmation: "password"
    )
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: "本人だけ更新",
        email: "self-only@example.com",
        id: other_user.id
      },
      notification_setting: {
        notification_enabled: "0",
        notification_time: "21:00"
      }
    }

    assert_redirected_to profile_url
    assert_equal "本人だけ更新", @user.reload.name
    assert_equal "別ユーザー", other_user.reload.name
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
