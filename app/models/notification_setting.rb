class NotificationSetting < ApplicationRecord
  VALID_REMINDER_DAYS = (0..6).to_a.freeze

  belongs_to :user

  serialize :reminder_days, coder: JSON, type: Array

  before_validation :normalize_reminder_days

  validates :user_id, uniqueness: true
  validates :notification_enabled, inclusion: { in: [ true, false ] }
  validates :notification_time, presence: true
  validates :reminder_days, presence: true, if: :notification_enabled?
  validate :reminder_days_are_valid

  private

  def normalize_reminder_days
    values = Array(reminder_days).reject(&:blank?)
    @invalid_reminder_days = values.reject { |day| day.to_s.match?(/\A[0-6]\z/) }
    normalized_days = values.filter_map { |day| Integer(day, exception: false) }

    self.reminder_days = normalized_days.uniq.sort
  end

  def reminder_days_are_valid
    valid_days = reminder_days.all? { |day| VALID_REMINDER_DAYS.include?(day) }
    return if @invalid_reminder_days.blank? && valid_days

    errors.add(:reminder_days, :inclusion)
  end
end
