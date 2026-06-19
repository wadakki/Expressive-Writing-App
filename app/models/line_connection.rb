class LineConnection < ApplicationRecord
  belongs_to :user

  before_validation :set_default_linked_at, on: :create

  enum :status, { linked: 0, blocked: 1 }, default: :linked, validate: true

  validates :user_id, uniqueness: true
  validates :line_user_id, presence: true, uniqueness: true
  validates :linked_at, presence: true

  private

  def set_default_linked_at
    self.linked_at ||= Time.current
  end
end
