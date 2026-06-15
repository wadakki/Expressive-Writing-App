require "test_helper"

class StaticPagesControllerTest < ActionDispatch::IntegrationTest
  test "shows the home page without the posts scaffold" do
    get root_url

    assert_response :success
    assert_select "h1", "気持ちを言葉にして、こころを整える"
    assert_select "a[href=?]", new_user_path, "ユーザー登録を始める"
    assert_select "h1", text: "Posts", count: 0
  end

  test "redirects logged-in users from the home page to the writing entry index" do
    user = User.create!(
      name: "トップページユーザー",
      email: "logged-in-home@example.com",
      password: "password",
      password_confirmation: "password"
    )
    post login_url, params: {
      user_session: {
        email: user.email,
        password: "password"
      }
    }

    get root_url

    assert_redirected_to writing_entries_url
  end

  test "shows the terms page" do
    get terms_url

    assert_response :success
    assert_select "h1", "利用規約"
  end

  test "shows the privacy page" do
    get privacy_url

    assert_response :success
    assert_select "h1", "プライバシーポリシー"
  end

  test "shows the contact page" do
    get contact_url

    assert_response :success
    assert_select "h1", "お問い合わせ"
  end
end
