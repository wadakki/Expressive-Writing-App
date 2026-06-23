class AddLastRemindedAtToNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :notification_settings, :last_reminded_at, :datetime
  end
end
