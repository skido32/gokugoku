# 端末ごとのログイン状態。時間では切れず、revoked_at で失効させる(F-AUTH-2, design.md 4.7)
class Session < ApplicationRecord
  LAST_USED_AT_PRECISION = 1.day # 書き込みを減らすため、1日1回だけ更新する

  belongs_to :user

  scope :active, -> { where(revoked_at: nil) }

  attr_reader :token # 平文は、作った直後のこのオブジェクトにだけ残る

  def self.digest(token)
    OpenSSL::Digest::SHA256.hexdigest(token.to_s)
  end

  def self.start!(user)
    token = SecureRandom.urlsafe_base64(32) # 256ビット
    create!(user:, token_digest: digest(token), last_used_at: Time.current).tap do |session|
      session.instance_variable_set(:@token, token)
    end
  end

  def self.authenticate(token)
    return if token.blank?

    active.find_by(token_digest: digest(token))&.tap(&:touch_last_used)
  end

  def revoke!
    update!(revoked_at: Time.current) unless revoked?
  end

  def revoked?
    revoked_at.present?
  end

  def touch_last_used
    now = Time.current
    update_column(:last_used_at, now) if last_used_at <= now - LAST_USED_AT_PRECISION
  end
end
