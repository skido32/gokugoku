# 端末ごとのログイン状態(F-AUTH-2)。トークンの平文は持たず、SHA-256 だけを保存する
class CreateSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :sessions, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :token_digest, null: false, limit: 64
      t.datetime :last_used_at, null: false
      t.datetime :revoked_at
      t.timestamps

      t.index :token_digest, unique: true
    end
  end
end
