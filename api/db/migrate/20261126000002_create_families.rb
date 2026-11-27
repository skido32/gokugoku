class CreateFamilies < ActiveRecord::Migration[8.1]
  def change
    create_table :families, id: :uuid do |t|
      t.string :name, null: false, limit: 30
      t.string :time_zone, null: false, default: "Asia/Tokyo"
      t.string :default_feeding_kind, null: false, default: "formula"
      t.timestamps

      t.check_constraint "default_feeding_kind IN ('formula', 'breast')", name: "families_default_feeding_kind_check"
    end
  end
end
