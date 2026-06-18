class CreateNotificationSettings < ActiveRecord::Migration[7.2]
  def change
    create_table :notification_settings do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.boolean :notification_enabled, null: false, default: false
      t.time :notification_time, null: false

      t.timestamps
    end
  end
end
