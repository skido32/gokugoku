class CreateMemberships < ActiveRecord::Migration[8.1]
  def change
    create_table :memberships, id: :uuid do |t|
      # MVP では、1人は1つの家族にだけ所属する(F-FAM-5)
      t.references :user, type: :uuid, null: false, index: { unique: true }, foreign_key: { on_delete: :cascade }
      t.references :family, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :role, null: false
      t.timestamps

      t.check_constraint "role IN ('owner', 'member')", name: "memberships_role_check"
    end
  end
end
