# 機種変更のための引き継ぎコード(F-AUTH-3)。コードの平文は持たず、HMAC だけを保存する
class CreateTransferCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :transfer_codes, id: :uuid do |t|
      t.references :user, type: :uuid, null: false, foreign_key: { on_delete: :cascade }
      t.string :code_digest, null: false, limit: 64
      t.datetime :expires_at, null: false
      t.datetime :used_at
      t.timestamps

      t.index :code_digest, unique: true
    end
  end
end
