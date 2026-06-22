# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[7.2].define(version: 2026_06_22_000000) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "authentications", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "provider", null: false
    t.string "uid", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["provider", "uid"], name: "index_authentications_on_provider_and_uid", unique: true
    t.index ["user_id", "provider"], name: "index_authentications_on_user_id_and_provider", unique: true
  end

  create_table "line_connections", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "line_user_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "linked_at", null: false
    t.datetime "last_notified_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["line_user_id"], name: "index_line_connections_on_line_user_id", unique: true
    t.index ["user_id"], name: "index_line_connections_on_user_id", unique: true
    t.check_constraint "status = ANY (ARRAY[0, 1])", name: "line_connections_status_values"
  end

  create_table "notification_settings", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.boolean "notification_enabled", default: false, null: false
    t.time "notification_time", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "reminder_days", default: "[0,1,2,3,4,5,6]", null: false
    t.index ["user_id"], name: "index_notification_settings_on_user_id", unique: true
    t.check_constraint "reminder_days::text ~ '^\\[([0-6](,[0-6])*)?\\]$'::text", name: "notification_settings_reminder_days_values"
  end

  create_table "users", force: :cascade do |t|
    t.string "name", limit: 50, null: false
    t.string "email", null: false
    t.string "crypted_password"
    t.string "salt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
  end

  create_table "writing_entries", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "before_happiness_score"
    t.integer "after_happiness_score"
    t.text "event_detail"
    t.text "negative_emotion_detail"
    t.text "positive_emotion_detail"
    t.text "unforgiven_target_detail"
    t.text "tomorrow_hope"
    t.integer "status", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "timer_remaining_seconds", default: 480, null: false
    t.index ["user_id"], name: "index_writing_entries_on_user_id"
    t.check_constraint "after_happiness_score IS NULL OR after_happiness_score >= 1 AND after_happiness_score <= 10", name: "writing_entries_after_happiness_score_range"
    t.check_constraint "before_happiness_score IS NULL OR before_happiness_score >= 1 AND before_happiness_score <= 10", name: "writing_entries_before_happiness_score_range"
    t.check_constraint "status = ANY (ARRAY[0, 1])", name: "writing_entries_status_values"
    t.check_constraint "timer_remaining_seconds >= 0 AND timer_remaining_seconds <= 480", name: "writing_entries_timer_remaining_seconds_range"
  end

  add_foreign_key "authentications", "users"
  add_foreign_key "line_connections", "users"
  add_foreign_key "notification_settings", "users"
  add_foreign_key "writing_entries", "users"
end
