class DropPosts < ActiveRecord::Migration[7.2]
  def change
    drop_table :posts do |t|
      t.string :title
      t.timestamps
    end
  end
end
