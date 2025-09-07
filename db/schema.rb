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

ActiveRecord::Schema[8.0].define(version: 2025_09_07_010407) do
  create_table "users", id: { type: :string, limit: 36 }, charset: "utf8mb4", collation: "utf8mb4_0900_ai_ci", force: :cascade do |t|
    t.string "email", null: false
    t.string "password_digest", null: false
    t.string "lasid", limit: 4
    t.integer "role", default: 0, null: false
    t.string "first_name"
    t.string "last_name"
    t.string "nickname"
    t.date "date_of_birth"
    t.datetime "last_login_at"
    t.integer "login_count", default: 0
    t.datetime "deleted_at"
    t.string "external_id", limit: 36, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["external_id"], name: "index_users_on_external_id", unique: true
    t.index ["lasid"], name: "index_users_on_lasid", unique: true
    t.index ["role"], name: "index_users_on_role"
  end
end
