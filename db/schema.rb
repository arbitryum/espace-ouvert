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

ActiveRecord::Schema[8.1].define(version: 2026_10_17_090000) do
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

  create_table "addresses", force: :cascade do |t|
    t.string "raw_address", null: false
    t.string "label", default: "", null: false
    t.string "city", default: "", null: false
    t.string "postal_code", default: "", null: false
    t.string "city_code", default: "", null: false
    t.string "department_code", default: "", null: false
    t.string "department_name", default: "", null: false
    t.string "region_name", default: "", null: false
    t.text "search_text", default: "", null: false
    t.float "latitude"
    t.float "longitude"
    t.string "ban_id", default: "", null: false
    t.float "ban_score"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["raw_address"], name: "index_addresses_on_raw_address", unique: true
  end

  create_table "care_homes", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.bigint "address_details_id"
    t.string "legal_status", default: "", null: false
    t.string "contact_name", default: "", null: false
    t.string "contact_email", default: "", null: false
    t.string "group_name", default: "", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["address_details_id"], name: "index_care_homes_on_address_details_id"
  end

  create_table "coworking_projects", force: :cascade do |t|
    t.string "name", null: false
    t.string "organization_name", null: false
    t.text "description", null: false
    t.string "location", null: false
    t.bigint "care_home_id"
    t.string "status", default: "draft", null: false
    t.boolean "published", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["care_home_id"], name: "index_coworking_projects_on_care_home_id"
  end

  create_table "ehpad_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "establishment_name", null: false
    t.string "establishment_address", null: false
    t.string "contact_name", null: false
    t.string "status", default: "pending", null: false
    t.boolean "participates_in_spaces", default: false, null: false
    t.boolean "participates_in_coworking", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_ehpad_profiles_on_user_id", unique: true
  end

  create_table "nonprofit_organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "address", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recurring_availabilities", force: :cascade do |t|
    t.bigint "space_id", null: false
    t.integer "weekday", null: false
    t.time "start_time", null: false
    t.time "end_time", null: false
    t.string "notes", default: "", null: false
    t.boolean "active", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_id"], name: "index_recurring_availabilities_on_space_id"
  end

  create_table "sessions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "ip_address"
    t.string "user_agent"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "space_images", force: :cascade do |t|
    t.bigint "space_id", null: false
    t.string "alt_text", default: "", null: false
    t.integer "position", default: 0, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["space_id"], name: "index_space_images_on_space_id"
  end

  create_table "spaces", force: :cascade do |t|
    t.bigint "care_home_id", null: false
    t.text "name", null: false
    t.text "availability", default: "", null: false
    t.text "description", default: "", null: false
    t.datetime "published_at", null: false
    t.string "status", default: "available", null: false
    t.string "publication_status", default: "published", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["care_home_id"], name: "index_spaces_on_care_home_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email_address", null: false
    t.string "password_digest", null: false
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "care_homes", "addresses", column: "address_details_id", on_delete: :nullify
  add_foreign_key "coworking_projects", "care_homes", on_delete: :nullify
  add_foreign_key "ehpad_profiles", "users", on_delete: :cascade
  add_foreign_key "recurring_availabilities", "spaces", on_delete: :cascade
  add_foreign_key "sessions", "users"
  add_foreign_key "space_images", "spaces", on_delete: :cascade
  add_foreign_key "spaces", "care_homes", on_delete: :cascade
end
