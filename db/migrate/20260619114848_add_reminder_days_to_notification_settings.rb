class AddReminderDaysToNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    add_column :notification_settings, :reminder_days, :string,
               default: "[0,1,2,3,4,5,6]", null: false

    add_check_constraint :notification_settings,
                         "reminder_days ~ '^\\[([0-6](,[0-6])*)?\\]$'",
                         name: "notification_settings_reminder_days_values"
  end
end
