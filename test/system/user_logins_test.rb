require "application_system_test_case"

class UserLoginsTest < ApplicationSystemTestCase
  driven_by :rack_test

  setup do
    @user = User.create!(
      name: "ログイン確認ユーザー",
      email: "system-login@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "shows LINE Login beside the existing password login" do
    visit login_path

    assert_link "LINEでログイン", href: line_login_path

    fill_in "メールアドレス", with: @user.email
    fill_in "パスワード", with: "password"
    click_button "ログインする"

    assert_current_path writing_entries_path
    assert_text "これまでの筆記開示"
  end
end
