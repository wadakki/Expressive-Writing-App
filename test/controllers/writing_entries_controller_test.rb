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

  test "redirects guests from the writing entry index to login" do
    get writing_entries_url

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  test "shows only the current user's completed entries newest first" do
    other_user = User.create!(
      name: "別ユーザー",
      email: "index-other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    older_entry = create_writing_entry(
      @user,
      event_detail: "古い完了投稿",
      created_at: 2.days.ago
    )
    newer_entry = create_writing_entry(
      @user,
      event_detail: "新しい完了投稿",
      created_at: 1.day.ago
    )
    draft_entry = create_writing_entry(
      @user,
      event_detail: "表示されない下書き",
      status: :draft,
      created_at: Time.current
    )
    other_entry = create_writing_entry(
      other_user,
      event_detail: "表示されない他ユーザー投稿",
      created_at: Time.current
    )
    login_as(@user)

    get writing_entries_url

    assert_response :success
    assert_select "h1", "これまでの筆記開示"
    assert_select "article", count: 2
    assert_select "article##{dom_id(newer_entry)}"
    assert_select "article##{dom_id(older_entry)}"
    assert_select "article##{dom_id(draft_entry)}", count: 0
    assert_select "article##{dom_id(other_entry)}", count: 0
    assert_select "article" do |articles|
      assert_equal dom_id(newer_entry), articles.first["id"]
      assert_equal dom_id(older_entry), articles[1]["id"]
    end
  end

  test "shows an empty state when the current user has no completed entries" do
    create_writing_entry(
      @user,
      event_detail: "下書き",
      status: :draft
    )
    login_as(@user)

    get writing_entries_url

    assert_response :success
    assert_select "article", count: 0
    assert_select "h2", "まだ投稿はありません"
    assert_select "a[href=?]", new_writing_entry_path, "新しく書く"
  end

  test "hides the writing entry index link on the index page" do
    login_as(@user)

    get writing_entries_url

    assert_select "header a[href=?]", writing_entries_path, count: 0
    assert_select "header a[href=?]", new_writing_entry_path, "筆記開示を始める"
  end

  test "hides the new entry link on the new entry page" do
    login_as(@user)

    get new_writing_entry_url

    assert_select "header a[href=?]", new_writing_entry_path, count: 0
    assert_select "header a[href=?]", writing_entries_path, "投稿一覧"
  end

  test "shows the writing entry form to logged-in users" do
    login_as(@user)

    assert_no_difference("WritingEntry.count") do
      get new_writing_entry_url
    end

    assert_response :success
    assert_select "h1", "今日の気持ちを書き出す"
    assert_select "form[action=?][method=post]", writing_entries_path
    assert_select "input[name=?][min=1][max=10][step=1][required]",
                  "writing_entry[before_happiness_score]"
    assert_select "input[name=?][min=1][max=10][step=1][required]",
                  "writing_entry[after_happiness_score]"

    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      assert_select "textarea[name=?][maxlength=3000][required]",
                    "writing_entry[#{attribute}]"
    end

    assert_select "button[name=?][value=draft][formnovalidate]", "writing_entry[status]", "下書き保存"
    assert_select "button[name=?][value=completed]", "writing_entry[status]", "投稿する"
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

  test "redirects guests who try to create an entry" do
    assert_no_difference("WritingEntry.count") do
      post writing_entries_url, params: {
        writing_entry: valid_writing_entry_params
      }
    end

    assert_redirected_to login_url
  end

  test "creates a completed entry for the current user" do
    login_as(@user)

    assert_difference("@user.writing_entries.count", 1) do
      post writing_entries_url, params: {
        writing_entry: valid_writing_entry_params.merge(
          status: "completed",
          user_id: User.create!(
            name: "別ユーザー",
            email: "another-writing-user@example.com",
            password: "password",
            password_confirmation: "password"
          ).id
        )
      }
    end

    writing_entry = @user.writing_entries.order(:created_at).last

    assert_predicate writing_entry, :completed?
    assert_equal 5, writing_entry.before_happiness_score
    assert_equal 7, writing_entry.after_happiness_score
    assert_equal "今日あったこと", writing_entry.event_detail
    assert_equal "不安を感じた", writing_entry.negative_emotion_detail
    assert_equal "うれしかった", writing_entry.positive_emotion_detail
    assert_equal "まだ許せないこと", writing_entry.unforgiven_target_detail
    assert_equal "穏やかに過ごしたい", writing_entry.tomorrow_hope
    assert_redirected_to root_url
    assert_equal "投稿を保存しました", flash[:notice]
  end

  test "creates a draft entry for the current user" do
    login_as(@user)

    assert_difference("@user.writing_entries.count", 1) do
      post writing_entries_url, params: { writing_entry: { status: "draft" } }
    end

    writing_entry = @user.writing_entries.order(:created_at).last

    assert_predicate writing_entry, :draft?
    assert_nil writing_entry.before_happiness_score
    assert_nil writing_entry.after_happiness_score
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      assert_nil writing_entry.public_send(attribute)
    end
    assert_redirected_to root_url
    assert_equal "下書きを保存しました", flash[:notice]
  end

  test "renders the form with errors when the entry is invalid" do
    login_as(@user)

    assert_no_difference("WritingEntry.count") do
      post writing_entries_url, params: {
        writing_entry: valid_writing_entry_params.merge(
          event_detail: "あ" * 3001,
          status: "completed"
        )
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /入力内容を確認してください/
    assert_select "[role=alert]", text: /実際に起きたことは3000文字以内で入力してください/
    assert_select "textarea[name=?]", "writing_entry[event_detail]", text: "あ" * 3001
  end

  test "renders the form with errors when required fields are blank" do
    login_as(@user)

    assert_no_difference("WritingEntry.count") do
      post writing_entries_url, params: {
        writing_entry: {
          status: "completed"
        }
      }
    end

    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /書く前の幸福度を入力してください/
    assert_select "[role=alert]", text: /書いた後の幸福度を入力してください/
    assert_select "[role=alert]", text: /実際に起きたことを入力してください/
    assert_select "[role=alert]", text: /明日の希望を入力してください/
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

  def valid_writing_entry_params
    {
      before_happiness_score: 5,
      after_happiness_score: 7,
      event_detail: "今日あったこと",
      negative_emotion_detail: "不安を感じた",
      positive_emotion_detail: "うれしかった",
      unforgiven_target_detail: "まだ許せないこと",
      tomorrow_hope: "穏やかに過ごしたい"
    }
  end

  def create_writing_entry(user, attributes = {})
    user.writing_entries.create!(
      valid_writing_entry_params.merge(
        status: :completed,
        created_at: Time.current
      ).merge(attributes)
    )
  end
end
