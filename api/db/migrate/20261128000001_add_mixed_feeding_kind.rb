# 種類に「混合」を足し、いつもの種類を家族ごとから子どもごとに移す(F-FEED-3, F-FEED-4, F-CHILD-5)
class AddMixedFeedingKind < ActiveRecord::Migration[8.1]
  def change
    # 母乳の記録は量を持たない。先に既存データを合わせてから制約を貼る
    reversible do |dir|
      dir.up { execute "UPDATE feeding_events SET amount_ml = NULL WHERE kind = 'breast'" }
    end

    remove_check_constraint :feeding_events, "kind IN ('formula', 'breast')", name: "feeding_events_kind_check"
    add_check_constraint :feeding_events, "kind IN ('formula', 'breast', 'mixed')", name: "feeding_events_kind_check"
    add_check_constraint :feeding_events, "kind <> 'breast' OR amount_ml IS NULL", name: "feeding_events_breast_has_no_amount_check"

    add_column :children, :default_feeding_kind, :string, null: false, default: "formula"
    add_check_constraint :children, "default_feeding_kind IN ('formula', 'breast', 'mixed')", name: "children_default_feeding_kind_check"

    # 家族の設定を、その家族の子どもに引き継ぐ
    reversible do |dir|
      dir.up do
        execute <<~SQL
          UPDATE children SET default_feeding_kind = families.default_feeding_kind
          FROM families WHERE families.id = children.family_id
        SQL
      end
    end

    remove_check_constraint :families, "default_feeding_kind IN ('formula', 'breast')", name: "families_default_feeding_kind_check"
    remove_column :families, :default_feeding_kind, :string, null: false, default: "formula"
  end
end
