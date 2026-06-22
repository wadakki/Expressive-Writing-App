class CreateAuthentications < ActiveRecord::Migration[7.2]
  def change
    create_table :authentications do |t|
      t.references :user, null: false, foreign_key: true, index: false
      t.string :provider, null: false
      t.string :uid, null: false

      t.timestamps
    end

    add_index :authentications, %i[provider uid], unique: true
    add_index :authentications, %i[user_id provider], unique: true
  end
end
