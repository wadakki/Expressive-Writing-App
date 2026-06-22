require "test_helper"

class LineAccountLinkerTest < ActiveSupport::TestCase
  setup do
    @user = create_user("linker@example.com")
  end

  test "creates matching authentication and line connection records" do
    assert_difference([ "Authentication.count", "LineConnection.count" ], 1) do
      LineAccountLinker.call(user: @user, line_user_id: "U-linker-user")
    end

    assert_equal "U-linker-user", @user.authentications.find_by!(provider: "line").uid
    assert_equal "U-linker-user", @user.line_connection.line_user_id
    assert_predicate @user.line_connection, :linked?
  end

  test "rejects a LINE account owned by another user" do
    other_user = create_user("other-linker@example.com")
    other_user.authentications.create!(provider: "line", uid: "U-owned-user")
    other_user.create_line_connection!(line_user_id: "U-owned-user", status: :linked)

    assert_raises(LineAccountLinker::LinkingError) do
      LineAccountLinker.call(user: @user, line_user_id: "U-owned-user")
    end
    assert_empty @user.authentications
    assert_nil @user.line_connection
  end

  test "rejects replacing an existing LINE identity" do
    @user.authentications.create!(provider: "line", uid: "U-current-user")
    @user.create_line_connection!(line_user_id: "U-current-user", status: :linked)

    assert_raises(LineAccountLinker::LinkingError) do
      LineAccountLinker.call(user: @user, line_user_id: "U-different-user")
    end

    assert_equal "U-current-user", @user.authentications.find_by!(provider: "line").uid
    assert_equal "U-current-user", @user.line_connection.line_user_id
  end

  private

  def create_user(email)
    User.create!(
      name: "LINE連携確認ユーザー",
      email:,
      password: "password",
      password_confirmation: "password"
    )
  end
end
