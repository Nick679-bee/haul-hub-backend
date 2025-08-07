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

ActiveRecord::Schema[8.0].define(version: 2025_08_07_105912) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "drivers", force: :cascade do |t|
    t.string "name"
    t.string "email"
    t.string "phone"
    t.string "license_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "hauls", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "truck_id"
    t.string "haul_number", null: false
    t.string "status", default: "pending"
    t.string "haul_type"
    t.string "pickup_address", null: false
    t.string "pickup_city"
    t.string "pickup_state"
    t.string "pickup_zip"
    t.decimal "pickup_latitude", precision: 10, scale: 6
    t.decimal "pickup_longitude", precision: 10, scale: 6
    t.datetime "pickup_date"
    t.string "pickup_contact_name"
    t.string "pickup_contact_phone"
    t.text "pickup_instructions"
    t.string "delivery_address", null: false
    t.string "delivery_city"
    t.string "delivery_state"
    t.string "delivery_zip"
    t.decimal "delivery_latitude", precision: 10, scale: 6
    t.decimal "delivery_longitude", precision: 10, scale: 6
    t.datetime "delivery_date"
    t.string "delivery_contact_name"
    t.string "delivery_contact_phone"
    t.text "delivery_instructions"
    t.string "load_type"
    t.text "load_description"
    t.decimal "load_weight", precision: 10, scale: 2
    t.decimal "load_volume", precision: 10, scale: 2
    t.boolean "load_hazardous", default: false
    t.text "special_requirements"
    t.decimal "distance_miles", precision: 8, scale: 2
    t.decimal "estimated_duration_hours", precision: 6, scale: 2
    t.decimal "quoted_price", precision: 10, scale: 2
    t.decimal "final_price", precision: 10, scale: 2
    t.decimal "fuel_cost", precision: 8, scale: 2
    t.string "payment_status", default: "pending"
    t.string "payment_method"
    t.datetime "started_at"
    t.datetime "completed_at"
    t.text "notes"
    t.text "completion_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["delivery_date"], name: "index_hauls_on_delivery_date"
    t.index ["haul_number"], name: "index_hauls_on_haul_number", unique: true
    t.index ["pickup_date"], name: "index_hauls_on_pickup_date"
    t.index ["status"], name: "index_hauls_on_status"
    t.index ["truck_id"], name: "index_hauls_on_truck_id"
    t.index ["user_id", "status"], name: "index_hauls_on_user_id_and_status"
    t.index ["user_id"], name: "index_hauls_on_user_id"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti", unique: true
  end

  create_table "trucks", force: :cascade do |t|
    t.string "make"
    t.string "model"
    t.integer "year"
    t.string "license_plate"
    t.string "vin"
    t.decimal "capacity"
    t.string "fuel_type"
    t.string "status"
    t.date "insurance_expiry"
    t.date "registration_expiry"
    t.date "last_maintenance"
    t.text "notes"
    t.bigint "user_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_trucks_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.string "phone"
    t.string "role"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "hauls", "trucks"
  add_foreign_key "hauls", "users"
  add_foreign_key "trucks", "users"
end
