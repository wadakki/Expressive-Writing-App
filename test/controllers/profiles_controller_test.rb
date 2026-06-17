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
    assert_select "dd", "プロフィールユーザー"
    assert_select "dd", "profile@example.com"
  end

  private

  def login_as(user)
    post login_url, params: {
      user_session: { email: user.email, password: "password" }
    }
  end
end
