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

ActiveRecord::Schema[8.0].define(version: 2025_08_03_101507) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "type", null: false
    t.string "first_name", null: false
    t.string "last_name"
    t.string "display_name"
    t.text "bio"
    t.date "date_of_birth"
    t.integer "gender"
    t.string "location_city"
    t.string "location_state"
    t.string "location_country", default: "India"
    t.string "website_url"
    t.string "instagram_url"
    t.string "youtube_url"
    t.json "privacy_settings", default: {}
    t.integer "height_cm"
    t.integer "weight_kg"
    t.integer "preferred_foot"
    t.integer "playing_status", default: 0
    t.integer "availability", default: 0
    t.text "achievements", default: [], array: true
    t.json "training_history", default: []
    t.integer "experience_years"
    t.text "coaching_philosophy"
    t.text "certifications", default: [], array: true
    t.decimal "hourly_rate", precision: 10, scale: 2
    t.string "currency", default: "INR"
    t.boolean "available_for_hire", default: true
    t.json "coaching_history", default: []
    t.string "club_name"
    t.integer "club_type"
    t.integer "establishment_year"
    t.text "facilities", default: [], array: true
    t.text "programs_offered", default: [], array: true
    t.string "contact_person"
    t.string "contact_email"
    t.string "contact_phone"
    t.text "address"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "slug"
    t.index ["availability"], name: "index_profiles_on_availability"
    t.index ["club_type"], name: "index_profiles_on_club_type"
    t.index ["location_city", "location_state"], name: "index_profiles_on_location_city_and_location_state"
    t.index ["playing_status"], name: "index_profiles_on_playing_status"
    t.index ["slug"], name: "index_profiles_on_slug", unique: true
    t.index ["type"], name: "index_profiles_on_type"
    t.index ["user_id"], name: "index_profiles_on_user_id"
  end

  create_table "sports", force: :cascade do |t|
    t.string "name"
    t.string "category"
    t.boolean "active"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "user_sports", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "sport_id", null: false
    t.string "position"
    t.integer "skill_level"
    t.integer "years_experience"
    t.boolean "primary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["sport_id"], name: "index_user_sports_on_sport_id"
    t.index ["user_id"], name: "index_user_sports_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "phone"
    t.integer "user_type", null: false
    t.boolean "verified", default: false
    t.string "first_name"
    t.string "last_name"
    t.boolean "active", default: true
    t.datetime "last_sign_in_at"
    t.string "phone_verification_code"
    t.datetime "phone_verification_sent_at"
    t.integer "posts_count", default: 0
    t.integer "connections_count", default: 0
    t.datetime "last_message_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.boolean "profile_completed", default: false
    t.index ["active"], name: "index_users_on_active"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["phone"], name: "index_users_on_phone", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["user_type"], name: "index_users_on_user_type"
    t.index ["verified"], name: "index_users_on_verified"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "profiles", "users"
  add_foreign_key "user_sports", "sports"
  add_foreign_key "user_sports", "users"
end
