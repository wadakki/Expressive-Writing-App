class AddTimerRemainingSecondsToWritingEntries < ActiveRecord::Migration[7.2]
  def change
    add_column :writing_entries,
               :timer_remaining_seconds,
               :integer,
               null: false,
               default: 480

    add_check_constraint :writing_entries,
                         "timer_remaining_seconds >= 0 AND timer_remaining_seconds <= 480",
                         name: "writing_entries_timer_remaining_seconds_range"
  end
end
