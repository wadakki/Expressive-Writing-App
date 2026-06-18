require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and matching passwords" do
    user = build_user

    assert user.valid?
  end

  test "requires a name" do
    user = build_user(name: nil)

    assert_not user.valid?
    assert_includes user.errors[:name], "を入力してください"
  end

  test "allows a name with 50 characters" do
    user = build_user(name: "a" * 50)

    assert user.valid?
  end

  test "rejects a name longer than 50 characters" do
    user = build_user(name: "a" * 51)

    assert_not user.valid?
    assert_includes user.errors[:name], "は50文字以内で入力してください"
  end

  test "requires an email" do
    user = build_user(email: nil)

    assert_not user.valid?
    assert_includes user.errors[:email], "を入力してください"
  end

  test "requires a valid email format" do
    user = build_user(email: "invalid")

    assert_not user.valid?
    assert_includes user.errors[:email], "は不正な値です"
  end

  test "requires a unique email regardless of case" do
    build_user(email: "user@example.com").save!
    user = build_user(email: "USER@example.com")

    assert_not user.valid?
    assert_includes user.errors[:email], "はすでに存在します"
  end

  test "requires a password with at least eight characters" do
    user = build_user(password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors[:password], "は8文字以上で入力してください"
  end

  test "requires password confirmation to match" do
    user = build_user(password_confirmation: "different-password")

    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "とパスワードの入力が一致しません"
  end

  test "authenticates with Sorcery" do
    user = build_user
    user.save!

    assert_equal user, User.authenticate(user.email, "password")
    assert_nil User.authenticate(user.email, "wrong-password")
  end

  test "has one notification setting" do
    user = build_user(email: "notification-owner@example.com")
    user.save!
    notification_setting = user.create_notification_setting!(
      notification_enabled: true,
      notification_time: "21:00"
    )

    assert_equal notification_setting, user.notification_setting
  end

  private

  def build_user(name: "Test User", email: "user@example.com", password: "password",
                 password_confirmation: "password")
    User.new(name:, email:, password:, password_confirmation:)
  end
end
