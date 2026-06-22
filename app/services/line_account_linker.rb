class LineAccountLinker
  class LinkingError < StandardError; end

  def self.call(user:, line_user_id:)
    new(user:, line_user_id:).call
  end

  def initialize(user:, line_user_id:)
    @user = user
    @line_user_id = line_user_id
  end

  def call
    ensure_line_account_available!

    ActiveRecord::Base.transaction do
      update_authentication!
      update_line_connection!
    end
  end

  private

  attr_reader :user, :line_user_id

  def ensure_line_account_available!
    authentication = Authentication.find_by(provider: "line", uid: line_user_id)
    connection = LineConnection.find_by(line_user_id:)
    owners = [ authentication&.user_id, connection&.user_id ].compact
    raise LinkingError if owners.any? { |user_id| user_id != user.id }
  end

  def update_authentication!
    authentication = user.authentications.find_or_initialize_by(provider: "line")
    ensure_same_identity!(authentication.uid) if authentication.persisted?
    authentication.update!(uid: line_user_id)
  end

  def update_line_connection!
    line_connection = user.line_connection || user.build_line_connection
    ensure_same_identity!(line_connection.line_user_id) if line_connection.persisted?
    line_connection.update!(
      line_user_id:,
      status: :linked,
      linked_at: Time.current
    )
  end

  def ensure_same_identity!(current_uid)
    raise LinkingError unless current_uid == line_user_id
  end
end
