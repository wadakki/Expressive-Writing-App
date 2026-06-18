class NotificationSetting < ApplicationRecord
  belongs_to :user

  validates :user_id, uniqueness: true
  validates :notification_enabled, inclusion: { in: [ true, false ] }
  validates :notification_time, presence: true
end
