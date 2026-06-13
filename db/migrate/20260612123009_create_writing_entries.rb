class CreateWritingEntries < ActiveRecord::Migration[7.2]
  def change
    create_table :writing_entries do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :before_happiness_score
      t.integer :after_happiness_score
      t.text :event_detail
      t.text :negative_emotion_detail
      t.text :positive_emotion_detail
      t.text :unforgiven_target_detail
      t.text :tomorrow_hope
      t.integer :status, null: false, default: 0

      t.timestamps
    end

    add_check_constraint :writing_entries,
                         "before_happiness_score IS NULL OR before_happiness_score BETWEEN 1 AND 10",
                         name: "writing_entries_before_happiness_score_range"
    add_check_constraint :writing_entries,
                         "after_happiness_score IS NULL OR after_happiness_score BETWEEN 1 AND 10",
                         name: "writing_entries_after_happiness_score_range"
    add_check_constraint :writing_entries,
                         "status IN (0, 1)",
                         name: "writing_entries_status_values"
  end
end
