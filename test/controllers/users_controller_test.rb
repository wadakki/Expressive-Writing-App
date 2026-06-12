require "test_helper"

class UsersControllerTest < ActionDispatch::IntegrationTest
  test "shows the signup form" do
    get new_user_url

    assert_response :success
    assert_select "h1", "ユーザー登録"
    assert_select "header"
    assert_select "footer"
    assert_select "header img[src=?]", "/expressive-writing-logo.png"
    assert_select "label[for=user_name]", "名前"
    assert_select "footer a[href=?]", terms_path, "利用規約"
    assert_select "footer a[href=?]", privacy_path, "プライバシーポリシー"
    assert_select "footer a[href=?]", contact_path, "お問い合わせ"
    assert_select "form[action=?][method=post]", users_path
    assert_select "input[name=?]", "user[name]"
    assert_select "input[name=?]", "user[email]"
    assert_select "input[name=?]", "user[password]"
    assert_select "input[name=?]", "user[password_confirmation]"
  end

  test "creates a user with valid parameters" do
    assert_difference("User.count", 1) do
      post users_url, params: {
        user: {
          name: "Test User",
          email: "signup@example.com",
          password: "password",
          password_confirmation: "password"
        }
      }
    end

    assert_redirected_to root_url
    assert_equal "ユーザー登録が完了しました", flash[:notice]
  end

  test "shows validation errors with invalid parameters" do
    assert_no_difference("User.count") do
      post users_url, params: {
        user: {
          name: "",
          email: "invalid",
          password: "short",
          password_confirmation: "different"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /入力内容を確認してください/
    assert_select "[role=alert]", text: /名前を入力してください/
    assert_select "[role=alert]", text: /メールアドレスは不正な値です/
    assert_select "form[action=?]", users_path
  end
end
