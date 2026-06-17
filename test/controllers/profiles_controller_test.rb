require "test_helper"

class ProfilesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "プロフィールユーザー",
      email: "profile@example.com",
      password: "password",
      password_confirmation: "password"
    )
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
    assert_select "form[action=?][method=post]", profile_path
    assert_select "input[name=?][value=?]", "user[name]", "プロフィールユーザー"
    assert_select "input[name=?][value=?]", "user[email]", "profile@example.com"
    assert_select "input[type=password][name=?][value=?][disabled]", "masked_password", "********"
    assert_select "input[type=password][name=?]", "user[password]"
    assert_select "input[type=password][name=?]", "user[password_confirmation]"
    assert_select "input[type=submit][value=?]", "更新する"
  end

  test "updates the current user's name and email" do
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: "更新ユーザー",
        email: "updated-profile@example.com",
        password: "",
        password_confirmation: ""
      }
    }

    assert_redirected_to profile_url
    assert_equal "プロフィールを更新しました", flash[:notice]
    @user.reload
    assert_equal "更新ユーザー", @user.name
    assert_equal "updated-profile@example.com", @user.email
  end

  test "updates the current user's password" do
    login_as(@user)

    patch profile_url, params: {
      user: {
        name: @user.name,
        email: @user.email,
        password: "new-password",
        password_confirmation: "new-password"
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
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /入力内容を確認してください/
    assert_select "[role=alert]", text: /名前を入力してください/
    assert_select "[role=alert]", text: /メールアドレスは不正な値です/
    assert_select "[role=alert]", text: /パスワードは8文字以上で入力してください/
    assert_select "input[name=?][value=?]", "user[email]", "invalid-email"
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
      }
    }

    assert_redirected_to profile_url
    assert_equal "本人だけ更新", @user.reload.name
    assert_equal "別ユーザー", other_user.reload.name
  end

  private

  def login_as(user)
    post login_url, params: {
      user_session: { email: user.email, password: "password" }
    }
  end
end
