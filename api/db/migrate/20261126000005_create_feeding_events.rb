class CreateFeedingEvents < ActiveRecord::Migration[8.1]
  def change
    create_table :feeding_events, id: :uuid do |t|
      t.references :family, type: :uuid, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.uuid :child_id, null: false
      t.references :recorded_by, type: :uuid, index: false, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :fed_at, null: false
      t.string :kind, null: false
      t.integer :amount_ml
      t.uuid :operation_id, null: false
      t.string :client_request_id, null: false, limit: 64
      t.datetime :deleted_at
      t.timestamps

      t.check_constraint "kind IN ('formula', 'breast')", name: "feeding_events_kind_check"
      t.check_constraint "amount_ml BETWEEN 0 AND 500", name: "feeding_events_amount_ml_check"
    end

    # 記録の家族と、子どもの家族が一致することを DB で保証する
    add_foreign_key :feeding_events, :children, column: [ :family_id, :child_id ], primary_key: [ :family_id, :id ], on_delete: :cascade

    # 冪等性の最終防御。論理削除済みも対象にする(design.md 4.1, 4.6)
    add_index :feeding_events, [ :family_id, :client_request_id, :child_id ], unique: true, name: "index_feeding_events_idempotency"
    add_index :feeding_events, [ :family_id, :fed_at ], order: { fed_at: :desc }, where: "deleted_at IS NULL", name: "index_feeding_events_active_by_family"
    add_index :feeding_events, [ :child_id, :fed_at ], order: { fed_at: :desc }, where: "deleted_at IS NULL", name: "index_feeding_events_active_by_child"
    add_index :feeding_events, :operation_id
  end
end
