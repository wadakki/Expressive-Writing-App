require "test_helper"

class LineConnectionTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(
      name: "LINE連携ユーザー",
      email: "line-connection@example.com",
      password: "password",
      password_confirmation: "password"
    )
  end

  test "is valid with a user line user id and status" do
    line_connection = build_line_connection

    assert line_connection.valid?
  end

  test "belongs to a user" do
    line_connection = build_line_connection
    line_connection.save!

    assert_equal @user, line_connection.user
    assert_equal line_connection, @user.line_connection
  end

  test "destroys line connection when the user is destroyed" do
    line_connection = build_line_connection
    line_connection.save!

    assert_difference("LineConnection.count", -1) do
      @user.destroy!
    end
    assert_not LineConnection.exists?(line_connection.id)
  end

  test "requires a user" do
    line_connection = build_line_connection(user: nil)

    assert_not line_connection.valid?
    assert_includes line_connection.errors[:user], "を入力してください"
  end

  test "allows one line connection per user" do
    build_line_connection.save!
    duplicate_connection = build_line_connection(line_user_id: "line-user-duplicate")

    assert_not duplicate_connection.valid?
    assert_includes duplicate_connection.errors[:user_id], "はすでに存在します"
  end

  test "requires a line user id" do
    line_connection = build_line_connection(line_user_id: nil)

    assert_not line_connection.valid?
    assert_includes line_connection.errors[:line_user_id], "を入力してください"
  end

  test "requires a unique line user id" do
    build_line_connection.save!
    other_user = create_user(email: "line-connection-other@example.com")
    duplicate_connection = build_line_connection(
      user: other_user,
      line_user_id: "line-user-123"
    )

    assert_not duplicate_connection.valid?
    assert_includes duplicate_connection.errors[:line_user_id], "はすでに存在します"
  end

  test "defines linked and blocked statuses" do
    assert_equal({ "linked" => 0, "blocked" => 1 }, LineConnection.statuses)
  end

  test "defaults status to linked" do
    assert_predicate @user.build_line_connection(line_user_id: "line-user-123"), :linked?
  end

  test "accepts blocked status" do
    line_connection = build_line_connection(status: :blocked)

    assert line_connection.valid?
    assert_predicate line_connection, :blocked?
  end

  test "sets linked at by default" do
    line_connection = build_line_connection(linked_at: nil)
    line_connection.valid?

    assert line_connection.linked_at.present?
  end

  test "accepts a last notified at timestamp" do
    notified_at = Time.current
    line_connection = build_line_connection(last_notified_at: notified_at)

    assert line_connection.valid?
    assert_equal notified_at.to_i, line_connection.last_notified_at.to_i
  end

  test "allows last notified at to be blank" do
    assert build_line_connection(last_notified_at: nil).valid?
  end

  test "rejects an invalid status" do
    line_connection = build_line_connection(status: :invalid)

    assert_not line_connection.valid?
    assert_includes line_connection.errors[:status], "は一覧にありません"
  end

  private

  def build_line_connection(user: @user, line_user_id: "line-user-123", status: :linked,
                            linked_at: Time.current, last_notified_at: nil)
    LineConnection.new(user:, line_user_id:, status:, linked_at:, last_notified_at:)
  end

  def create_user(email:)
    User.create!(
      name: "別LINE連携ユーザー",
      email:,
      password: "password",
      password_confirmation: "password"
    )
  end
end
