class CreateLineConnections < ActiveRecord::Migration[7.2]
  def change
    create_table :line_connections do |t|
      t.references :user, null: false, foreign_key: true, index: { unique: true }
      t.string :line_user_id, null: false
      t.integer :status, null: false, default: 0
      t.datetime :linked_at, null: false
      t.datetime :last_notified_at

      t.timestamps
    end

    add_index :line_connections, :line_user_id, unique: true
    add_check_constraint :line_connections, "status IN (0, 1)",
                         name: "line_connections_status_values"
  end
end
