require "test_helper"

class AuthenticationTest < ActiveSupport::TestCase
  setup do
    @user = create_user(email: "authentication@example.com")
  end

  test "is valid with a user provider and uid" do
    assert build_authentication.valid?
  end

  test "belongs to a user" do
    authentication = build_authentication
    authentication.save!

    assert_equal @user, authentication.user
    assert_includes @user.authentications, authentication
  end

  test "destroys authentications when the user is destroyed" do
    authentication = build_authentication
    authentication.save!

    assert_difference("Authentication.count", -1) do
      @user.destroy!
    end
    assert_not Authentication.exists?(authentication.id)
  end

  test "requires a user" do
    authentication = build_authentication(user: nil)

    assert_not authentication.valid?
    assert_includes authentication.errors[:user], "を入力してください"
  end

  test "requires a provider" do
    authentication = build_authentication(provider: nil)

    assert_not authentication.valid?
    assert_includes authentication.errors[:provider], "を入力してください"
  end

  test "requires a uid" do
    authentication = build_authentication(uid: nil)

    assert_not authentication.valid?
    assert_includes authentication.errors[:uid], "を入力してください"
  end

  test "requires a unique uid within a provider" do
    build_authentication.save!
    other_user = create_user(email: "other-authentication@example.com")
    duplicate = build_authentication(user: other_user)

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:uid], "はすでに存在します"
  end

  test "allows the same uid for different providers" do
    build_authentication.save!
    other_user = create_user(email: "other-provider@example.com")
    authentication = build_authentication(user: other_user, provider: "google")

    assert authentication.valid?
  end

  test "allows one authentication per provider for each user" do
    build_authentication.save!
    duplicate = build_authentication(uid: "line-user-duplicate")

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:provider], "はすでに存在します"
  end

  test "allows a user to authenticate with different providers" do
    build_authentication.save!
    authentication = build_authentication(provider: "google", uid: "google-user-123")

    assert authentication.valid?
  end

  test "defines unique database indexes" do
    indexes = ActiveRecord::Base.connection.indexes(:authentications)

    provider_uid_index = indexes.find { |index| index.columns == %w[provider uid] }
    user_provider_index = indexes.find { |index| index.columns == %w[user_id provider] }

    assert provider_uid_index
    assert provider_uid_index.unique
    assert user_provider_index
    assert user_provider_index.unique
  end

  private

  def build_authentication(user: @user, provider: "line", uid: "line-user-123")
    Authentication.new(user:, provider:, uid:)
  end

  def create_user(email:)
    User.create!(
      name: "外部認証ユーザー",
      email:,
      password: "password",
      password_confirmation: "password"
    )
  end
end
