# 機種変更のための引き継ぎコード。24時間有効で1回限り(F-AUTH-3, design.md 4.7)
class TransferCode < ApplicationRecord
  LENGTH = 12 # 約60ビット。家族ではなく利用者そのものを渡すので、招待コードより長くする
  LIFETIME = 24.hours

  belongs_to :user

  scope :usable, -> { where(used_at: nil).where("expires_at > ?", Time.current) }

  attr_reader :code # 平文は、発行した直後のこのオブジェクトにだけ残る

  def self.digest(code)
    SecretCode.digest(code, purpose: "transfer_code")
  end

  # 発行し直すと、古い未使用のコードは使えなくする
  def self.issue!(user)
    transaction do
      where(user:, used_at: nil).delete_all
      code = SecretCode.generate(LENGTH)
      create!(user:, code_digest: digest(code), expires_at: Time.current + LIFETIME).tap do |record|
        record.instance_variable_set(:@code, code)
      end
    end
  end

  # コードを使い、新しい端末のセッションを返す。使えないコードなら nil。
  # 同じトランザクションで、コードを使用済みにし、その利用者の他のセッションをすべて失効させる
  def self.redeem!(code)
    transaction do
      record = usable.lock.find_by(code_digest: digest(code))
      next if record.nil?

      now = Time.current
      record.update!(used_at: now)
      Session.active.where(user_id: record.user_id).update_all(revoked_at: now, updated_at: now)
      Session.start!(record.user)
    end
  end
end
