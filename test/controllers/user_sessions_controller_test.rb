require "test_helper"

class UserSessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "ログインユーザー",
      email: "login@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "shows the login form" do
    get login_url

    assert_response :success
    assert_select "h1", "ログイン"
    assert_select "form[action=?][method=post]", login_path
    assert_select "input[name=?]", "user_session[email]"
    assert_select "input[name=?]", "user_session[password]"
    assert_select "a[href=?]", new_user_path, "ユーザー登録"
    assert_select "header a[href=?]", login_path, "ログイン"
    assert_select "header a[href=?]", logout_path, count: 0
  end

  test "logs in with valid credentials" do
    post login_url, params: {
      user_session: {
        email: @user.email,
        password: "password"
      }
    }

    assert_redirected_to root_url
    assert_equal "ログインしました", flash[:notice]

    follow_redirect!
    assert_redirected_to writing_entries_url
    follow_redirect!
    assert_select "h1", "これまでの筆記開示"
    assert_select "a[href=?]", logout_path, "ログアウト"
    assert_select "header", text: /ログインユーザーさん/
    assert_select "header a[href=?]", login_path, count: 0
    assert_select "header a[href=?]", new_user_path, count: 0
    assert_select "header a[href=?]", writing_entries_path, count: 0
  end

  test "shows an error with invalid credentials" do
    post login_url, params: {
      user_session: {
        email: @user.email,
        password: "wrong-password"
      }
    }

    assert_response :unprocessable_entity
    assert_select "[role=status]", text: /メールアドレスまたはパスワードが正しくありません/
    assert_select "input[name=?][value=?]", "user_session[email]", @user.email
  end

  test "logs out" do
    post login_url, params: {
      user_session: {
        email: @user.email,
        password: "password"
      }
    }

    delete logout_url

    assert_redirected_to root_url
    assert_equal "ログアウトしました", flash[:notice]

    follow_redirect!
    assert_select "a[href=?]", login_path, "ログイン"
    assert_select "a[href=?]", logout_path, count: 0
  end
end
