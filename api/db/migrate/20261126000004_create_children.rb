class CreateChildren < ActiveRecord::Migration[8.1]
  def change
    create_table :children, id: :uuid do |t|
      t.references :family, type: :uuid, null: false, index: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false, limit: 20
      t.date :birthday
      t.string :color, null: false
      t.integer :position, null: false
      t.timestamps

      t.check_constraint "color IN ('blue', 'pink', 'green', 'orange', 'purple', 'yellow')", name: "children_color_check"
      t.check_constraint "position BETWEEN 0 AND 3", name: "children_position_check"
    end

    # 並べ替えで position を入れ替えられるように、トランザクションの終わりで検証する
    add_unique_constraint :children, [ :family_id, :position ], deferrable: :deferred, name: "children_family_id_position_key"
    # feeding_events から (family_id, child_id) で参照するため
    add_index :children, [ :family_id, :id ], unique: true
  end
end
