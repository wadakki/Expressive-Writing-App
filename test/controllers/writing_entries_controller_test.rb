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

  test "shows the current user's entries newest first with status labels" do
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
      event_detail: "表示される下書き",
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
    assert_select "article", count: 3
    assert_select "article##{dom_id(draft_entry)}"
    assert_select "article##{dom_id(newer_entry)}"
    assert_select "article##{dom_id(older_entry)}"
    assert_select "article##{dom_id(other_entry)}", count: 0
    assert_select "span", "下書き"
    assert_select "span", "投稿済み"
    assert_select "a[href=?]", writing_entry_path(newer_entry), "詳細を見る"
    assert_select "a[href=?]", edit_writing_entry_path(draft_entry), "編集を再開する"
    assert_select "article" do |articles|
      assert_equal dom_id(draft_entry), articles.first["id"]
      assert_equal dom_id(newer_entry), articles[1]["id"]
      assert_equal dom_id(older_entry), articles[2]["id"]
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
    assert_select "article", count: 1
    assert_select "a[href=?]", edit_writing_entry_path(WritingEntry.last), "編集を再開する"
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

  test "redirects guests from a writing entry detail to login" do
    writing_entry = create_writing_entry(@user)

    get writing_entry_url(writing_entry)

    assert_redirected_to login_url
    assert_equal "ログインしてください", flash[:alert]
  end

  test "shows all answers and happiness scores for a completed entry" do
    writing_entry = create_writing_entry(
      @user,
      before_happiness_score: 3,
      after_happiness_score: 8,
      event_detail: "詳細に表示する出来事",
      negative_emotion_detail: "詳細に表示する不安",
      positive_emotion_detail: "詳細に表示する喜び",
      unforgiven_target_detail: "詳細に表示する許せないこと",
      tomorrow_hope: "詳細に表示する明日の希望"
    )
    login_as(@user)

    get writing_entry_url(writing_entry)

    assert_response :success
    assert_select "h1", "筆記開示の記録"
    assert_select "time[datetime=?]", writing_entry.created_at.iso8601
    assert_select "section", text: /書く前の幸福度: 3/
    assert_select "section", text: /書いた後の幸福度: 8/
    assert_select "h2", text: /今日、実際に起きたこと/
    assert_select "p", "詳細に表示する出来事"
    assert_select "p", "詳細に表示する不安"
    assert_select "p", "詳細に表示する喜び"
    assert_select "p", "詳細に表示する許せないこと"
    assert_select "p", "詳細に表示する明日の希望"
    assert_select "a[href=?]", writing_entries_path, "投稿一覧へ戻る"
    assert_select "a[href=?]", edit_writing_entry_path(writing_entry), "編集する"
  end

  test "redirects guests from the edit page to login" do
    writing_entry = create_writing_entry(@user)

    get edit_writing_entry_url(writing_entry)

    assert_redirected_to login_url
  end

  test "shows the edit form with the existing values" do
    writing_entry = create_writing_entry(
      @user,
      before_happiness_score: 2,
      after_happiness_score: 9,
      event_detail: "編集前の出来事"
    )
    login_as(@user)

    get edit_writing_entry_url(writing_entry)

    assert_response :success
    assert_select "h1", "筆記開示を編集する"
    assert_select "form[action=?][method=post]", writing_entry_path(writing_entry)
    assert_select "input[name=?][value=2]", "writing_entry[before_happiness_score]"
    assert_select "input[name=?][value=9]", "writing_entry[after_happiness_score]"
    assert_select "textarea[name=?]", "writing_entry[event_detail]", text: "編集前の出来事"
    assert_select "button[name=?][value=completed]", "writing_entry[status]", "更新する"
    assert_select "button[value=draft]", count: 0
  end

  test "shows the edit form for a draft entry" do
    writing_entry = create_writing_entry(
      @user,
      event_detail: nil,
      negative_emotion_detail: nil,
      positive_emotion_detail: nil,
      unforgiven_target_detail: nil,
      tomorrow_hope: nil,
      before_happiness_score: nil,
      after_happiness_score: nil,
      status: :draft
    )
    login_as(@user)

    get edit_writing_entry_url(writing_entry)

    assert_response :success
    assert_select "h1", "筆記開示を編集する"
    assert_select "button[name=?][value=draft][formnovalidate]", "writing_entry[status]", "下書き保存"
    assert_select "button[name=?][value=completed]", "writing_entry[status]", "更新する"
    assert_select "a[href=?]", writing_entries_path, "編集をキャンセル"
  end

  test "updates the current user's completed entry" do
    writing_entry = create_writing_entry(@user)
    other_user = User.create!(
      name: "更新別ユーザー",
      email: "update-other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    login_as(@user)

    patch writing_entry_url(writing_entry), params: {
      writing_entry: valid_writing_entry_params.merge(
        event_detail: "更新後の出来事",
        before_happiness_score: 4,
        after_happiness_score: 9,
        status: "draft",
        user_id: other_user.id
      )
    }

    assert_redirected_to writing_entry_url(writing_entry)
    assert_equal "投稿を更新しました", flash[:notice]
    writing_entry.reload
    assert_equal @user, writing_entry.user
    assert_equal "更新後の出来事", writing_entry.event_detail
    assert_equal 4, writing_entry.before_happiness_score
    assert_equal 9, writing_entry.after_happiness_score
    assert_predicate writing_entry, :completed?
  end

  test "renders the edit form with errors when the update is invalid" do
    writing_entry = create_writing_entry(@user)
    login_as(@user)

    patch writing_entry_url(writing_entry), params: {
      writing_entry: valid_writing_entry_params.merge(
        event_detail: "",
        status: "completed"
      )
    }

    assert_response :unprocessable_entity
    assert_select "h1", "筆記開示を編集する"
    assert_select "[role=alert]", text: /実際に起きたことを入力してください/
    assert_select "textarea[name=?]", "writing_entry[event_detail]", text: ""
    assert_equal "今日あったこと", writing_entry.reload.event_detail
  end

  test "updates a draft entry as a draft" do
    writing_entry = create_writing_entry(@user, event_detail: nil, status: :draft)
    login_as(@user)

    patch writing_entry_url(writing_entry), params: {
      writing_entry: {
        event_detail: "下書き更新",
        status: "draft"
      }
    }

    assert_redirected_to writing_entries_url
    assert_equal "投稿を更新しました", flash[:notice]
    writing_entry.reload
    assert_predicate writing_entry, :draft?
    assert_equal "下書き更新", writing_entry.event_detail
  end

  test "updates a draft entry as completed" do
    writing_entry = create_writing_entry(@user, event_detail: nil, status: :draft)
    login_as(@user)

    patch writing_entry_url(writing_entry), params: {
      writing_entry: valid_writing_entry_params.merge(status: "completed")
    }

    assert_redirected_to writing_entry_url(writing_entry)
    writing_entry.reload
    assert_predicate writing_entry, :completed?
    assert_equal "今日あったこと", writing_entry.event_detail
  end

  test "does not edit or update another user's entry" do
    other_user = User.create!(
      name: "編集別ユーザー",
      email: "edit-other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    writing_entry = create_writing_entry(other_user)
    login_as(@user)

    get edit_writing_entry_url(writing_entry)
    assert_response :not_found

    patch writing_entry_url(writing_entry), params: {
      writing_entry: valid_writing_entry_params.merge(event_detail: "不正な更新")
    }
    assert_response :not_found
    assert_not_equal "不正な更新", writing_entry.reload.event_detail
  end

  test "does not show another user's entry" do
    other_user = User.create!(
      name: "詳細別ユーザー",
      email: "show-other@example.com",
      password: "password",
      password_confirmation: "password"
    )
    writing_entry = create_writing_entry(other_user)
    login_as(@user)

    get writing_entry_url(writing_entry)

    assert_response :not_found
  end

  test "does not show a draft entry" do
    writing_entry = create_writing_entry(
      @user,
      event_detail: nil,
      negative_emotion_detail: nil,
      positive_emotion_detail: nil,
      unforgiven_target_detail: nil,
      tomorrow_hope: nil,
      before_happiness_score: nil,
      after_happiness_score: nil,
      status: :draft
    )
    login_as(@user)

    get writing_entry_url(writing_entry)

    assert_response :not_found
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
