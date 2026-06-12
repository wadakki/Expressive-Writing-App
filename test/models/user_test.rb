require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "is valid with an email and matching passwords" do
    user = build_user

    assert user.valid?
  end

  test "requires a name" do
    user = build_user(name: nil)

    assert_not user.valid?
    assert_includes user.errors[:name], "can't be blank"
  end

  test "requires an email" do
    user = build_user(email: nil)

    assert_not user.valid?
    assert_includes user.errors[:email], "can't be blank"
  end

  test "requires a valid email format" do
    user = build_user(email: "invalid")

    assert_not user.valid?
    assert_includes user.errors[:email], "is invalid"
  end

  test "requires a unique email regardless of case" do
    build_user(email: "user@example.com").save!
    user = build_user(email: "USER@example.com")

    assert_not user.valid?
    assert_includes user.errors[:email], "has already been taken"
  end

  test "requires a password with at least eight characters" do
    user = build_user(password: "short", password_confirmation: "short")

    assert_not user.valid?
    assert_includes user.errors[:password], "is too short (minimum is 8 characters)"
  end

  test "requires password confirmation to match" do
    user = build_user(password_confirmation: "different-password")

    assert_not user.valid?
    assert_includes user.errors[:password_confirmation], "doesn't match Password"
  end

  test "authenticates with Sorcery" do
    user = build_user
    user.save!

    assert_equal user, User.authenticate(user.email, "password")
    assert_nil User.authenticate(user.email, "wrong-password")
  end

  private

  def build_user(name: "Test User", email: "user@example.com", password: "password",
                 password_confirmation: "password")
    User.new(name:, email:, password:, password_confirmation:)
  end
end
