require "test_helper"

class WritingEntryTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "Writing User",
      email: "writing@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "belongs to a user" do
    entry = @user.writing_entries.create!

    assert_equal @user, entry.user
    assert_includes @user.writing_entries, entry
  end

  test "destroys entries when the user is destroyed" do
    entry = @user.writing_entries.create!

    assert_difference("WritingEntry.count", -1) do
      @user.destroy!
    end
    assert_not WritingEntry.exists?(entry.id)
  end

  test "defines draft and completed statuses" do
    assert_equal({ "draft" => 0, "completed" => 1 }, WritingEntry.statuses)
  end

  test "defaults status to draft" do
    assert_predicate @user.writing_entries.build, :draft?
  end

  test "rejects an invalid status" do
    entry = @user.writing_entries.build(status: :invalid)

    assert_not entry.valid?
    assert_includes entry.errors[:status], "は一覧にありません"
  end

  test "accepts happiness scores from 1 through 10" do
    [ 1, 10 ].each do |score|
      entry = @user.writing_entries.build(
        before_happiness_score: score,
        after_happiness_score: score
      )

      assert entry.valid?
    end
  end

  test "rejects before happiness scores outside 1 through 10" do
    [ 0, 11 ].each do |score|
      entry = @user.writing_entries.build(before_happiness_score: score)

      assert_not entry.valid?
      assert entry.errors[:before_happiness_score].any?
    end
  end

  test "rejects after happiness scores outside 1 through 10" do
    [ 0, 11 ].each do |score|
      entry = @user.writing_entries.build(after_happiness_score: score)

      assert_not entry.valid?
      assert entry.errors[:after_happiness_score].any?
    end
  end

  test "allows happiness scores to be omitted while drafting" do
    assert @user.writing_entries.build.valid?
  end

  test "accepts detail attributes with 3000 characters" do
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      entry = @user.writing_entries.build(attribute => "あ" * 3000)

      assert entry.valid?, "#{attribute} should allow 3000 characters"
    end
  end

  test "rejects detail attributes longer than 3000 characters" do
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      entry = @user.writing_entries.build(attribute => "あ" * 3001)

      assert_not entry.valid?, "#{attribute} should reject 3001 characters"
      assert_includes(
        entry.errors[attribute],
        "は3000文字以内で入力してください"
      )
    end
  end
end
