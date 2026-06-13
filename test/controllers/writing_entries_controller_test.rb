require "test_helper"

class WritingEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      name: "投稿ユーザー",
      email: "writing-form@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "redirects guests to login" do
    get new_writing_entry_url

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  test "shows the writing entry form to logged-in users" do
    login_as(@user)

    assert_no_difference("WritingEntry.count") do
      get new_writing_entry_url
    end

    assert_response :success
    assert_select "h1", "今日の気持ちを書き出す"
    assert_select "form[action=?][method=post]", writing_entries_path
    assert_select "input[name=?][min=1][max=10][step=1]",
                  "writing_entry[before_happiness_score]"
    assert_select "input[name=?][min=1][max=10][step=1]",
                  "writing_entry[after_happiness_score]"

    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      assert_select "textarea[name=?][maxlength=3000]",
                    "writing_entry[#{attribute}]"
    end

    assert_select "input[type=submit][value=?]", "投稿する"
  end

  test "shows all fixed questions" do
    login_as(@user)

    get new_writing_entry_url

    assert_select "label", text: /今日、実際に起きたこと/
    assert_select "label", text: /ネガティブな感情/
    assert_select "label", text: /ポジティブな感情/
    assert_select "label", text: /起きたことの中で、許せない相手や出来事/
    assert_select "label", text: /明日をどのような一日にしたい/
  end

  test "shows the new entry link in the logged-in header" do
    login_as(@user)

    get root_url

    assert_select "header a[href=?]", new_writing_entry_path, "筆記開示を始める"
  end

  private

  def login_as(user)
    post login_url, params: {
      user_session: {
        email: user.email,
        password: "password"
      }
    }
  end
end
