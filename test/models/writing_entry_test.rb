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
    entry = @user.writing_entries.create!(valid_attributes)

    assert_equal @user, entry.user
    assert_includes @user.writing_entries, entry
  end

  test "destroys entries when the user is destroyed" do
    entry = @user.writing_entries.create!(valid_attributes)

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

  test "defaults timer remaining seconds to the writing timer duration" do
    assert_equal WritingEntry::TIMER_DURATION_SECONDS, @user.writing_entries.build.timer_remaining_seconds
  end

  test "rejects an invalid status" do
    entry = @user.writing_entries.build(valid_attributes.merge(status: :invalid))

    assert_not entry.valid?
    assert_includes entry.errors[:status], "は一覧にありません"
  end

  test "accepts happiness scores from 1 through 10" do
    [ 1, 10 ].each do |score|
      entry = @user.writing_entries.build(valid_attributes.merge(
        before_happiness_score: score,
        after_happiness_score: score
      ))

      assert entry.valid?
    end
  end

  test "rejects before happiness scores outside 1 through 10" do
    [ 0, 11 ].each do |score|
      entry = @user.writing_entries.build(
        valid_attributes.merge(before_happiness_score: score)
      )

      assert_not entry.valid?
      assert entry.errors[:before_happiness_score].any?
    end
  end

  test "rejects after happiness scores outside 1 through 10" do
    [ 0, 11 ].each do |score|
      entry = @user.writing_entries.build(
        valid_attributes.merge(after_happiness_score: score)
      )

      assert_not entry.valid?
      assert entry.errors[:after_happiness_score].any?
    end
  end

  test "requires happiness scores" do
    %i[before_happiness_score after_happiness_score].each do |attribute|
      entry = @user.writing_entries.build(
        valid_attributes.merge(attribute => nil, status: :completed)
      )

      assert_not entry.valid?
      assert_includes entry.errors[attribute], "を入力してください"
    end
  end

  test "requires all detail attributes" do
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      entry = @user.writing_entries.build(
        valid_attributes.merge(attribute => nil, status: :completed)
      )

      assert_not entry.valid?
      assert_includes entry.errors[attribute], "を入力してください"
    end
  end

  test "allows required fields to be omitted while drafting" do
    assert @user.writing_entries.build(status: :draft).valid?
  end

  test "accepts timer remaining seconds from zero through the duration" do
    [ 0, WritingEntry::TIMER_DURATION_SECONDS ].each do |seconds|
      entry = @user.writing_entries.build(valid_attributes.merge(timer_remaining_seconds: seconds))

      assert entry.valid?
    end
  end

  test "rejects timer remaining seconds outside zero through the duration" do
    [ -1, WritingEntry::TIMER_DURATION_SECONDS + 1 ].each do |seconds|
      entry = @user.writing_entries.build(valid_attributes.merge(timer_remaining_seconds: seconds))

      assert_not entry.valid?
      assert entry.errors[:timer_remaining_seconds].any?
    end
  end

  test "requires the timer to finish before completing" do
    entry = @user.writing_entries.build(
      valid_attributes.merge(status: :completed, timer_remaining_seconds: 1)
    )

    assert_not entry.valid?
    assert_includes entry.errors[:timer_remaining_seconds], "はタイマー終了後にしてください"
  end

  test "accepts detail attributes with 3000 characters" do
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      entry = @user.writing_entries.build(valid_attributes.merge(attribute => "あ" * 3000))

      assert entry.valid?, "#{attribute} should allow 3000 characters"
    end
  end

  test "rejects detail attributes longer than 3000 characters" do
    WritingEntry::DETAIL_ATTRIBUTES.each do |attribute|
      entry = @user.writing_entries.build(valid_attributes.merge(attribute => "あ" * 3001))

      assert_not entry.valid?, "#{attribute} should reject 3001 characters"
      assert_includes(
        entry.errors[attribute],
        "は3000文字以内で入力してください"
      )
    end
  end

  private

  def valid_attributes
    {
      before_happiness_score: 5,
      after_happiness_score: 7,
      event_detail: "今日あったこと",
      negative_emotion_detail: "不安を感じた",
      positive_emotion_detail: "うれしかった",
      unforgiven_target_detail: "まだ許せないこと",
      tomorrow_hope: "穏やかに過ごしたい",
      timer_remaining_seconds: 0
    }
  end
end
