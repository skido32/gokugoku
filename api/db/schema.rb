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

ActiveRecord::Schema[8.1].define(version: 2026_11_26_000005) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "children", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.string "name", limit: 20, null: false
    t.date "birthday"
    t.string "color", null: false
    t.integer "position", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id", "id"], name: "index_children_on_family_id_and_id", unique: true
    t.check_constraint "\"position\" >= 0 AND \"position\" <= 3", name: "children_position_check"
    t.check_constraint "color::text = ANY (ARRAY['blue'::character varying::text, 'pink'::character varying::text, 'green'::character varying::text, 'orange'::character varying::text, 'purple'::character varying::text, 'yellow'::character varying::text])", name: "children_color_check"
    t.unique_constraint ["family_id", "position"], deferrable: :deferred, name: "children_family_id_position_key"
  end

  create_table "families", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 30, null: false
    t.string "time_zone", default: "Asia/Tokyo", null: false
    t.string "default_feeding_kind", default: "formula", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.check_constraint "default_feeding_kind::text = ANY (ARRAY['formula'::character varying::text, 'breast'::character varying::text])", name: "families_default_feeding_kind_check"
  end

  create_table "feeding_events", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "family_id", null: false
    t.uuid "child_id", null: false
    t.uuid "recorded_by_id"
    t.datetime "fed_at", precision: nil, null: false
    t.string "kind", null: false
    t.integer "amount_ml"
    t.uuid "operation_id", null: false
    t.string "client_request_id", limit: 64, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["child_id", "fed_at"], name: "index_feeding_events_active_by_child", order: { fed_at: :desc }, where: "(deleted_at IS NULL)"
    t.index ["family_id", "client_request_id", "child_id"], name: "index_feeding_events_idempotency", unique: true
    t.index ["family_id", "fed_at"], name: "index_feeding_events_active_by_family", order: { fed_at: :desc }, where: "(deleted_at IS NULL)"
    t.index ["operation_id"], name: "index_feeding_events_on_operation_id"
    t.check_constraint "amount_ml >= 0 AND amount_ml <= 500", name: "feeding_events_amount_ml_check"
    t.check_constraint "kind::text = ANY (ARRAY['formula'::character varying::text, 'breast'::character varying::text])", name: "feeding_events_kind_check"
  end

  create_table "memberships", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.uuid "user_id", null: false
    t.uuid "family_id", null: false
    t.string "role", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["family_id"], name: "index_memberships_on_family_id"
    t.index ["user_id"], name: "index_memberships_on_user_id", unique: true
    t.check_constraint "role::text = ANY (ARRAY['owner'::character varying::text, 'member'::character varying::text])", name: "memberships_role_check"
  end

  create_table "users", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name", limit: 20
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_foreign_key "children", "families", on_delete: :cascade
  add_foreign_key "feeding_events", "children", column: ["family_id", "child_id"], primary_key: ["family_id", "id"], on_delete: :cascade
  add_foreign_key "feeding_events", "families", on_delete: :cascade
  add_foreign_key "feeding_events", "users", column: "recorded_by_id", on_delete: :nullify
  add_foreign_key "memberships", "families", on_delete: :cascade
  add_foreign_key "memberships", "users", on_delete: :cascade
end
