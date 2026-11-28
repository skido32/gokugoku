class User < ApplicationRecord
  NAME_MAX_LENGTH = 20
  ABANDONED_AFTER = 30.days

  has_one :membership, dependent: nil # DB の ON DELETE CASCADE で消す
  has_one :family, through: :membership
  has_many :sessions, dependent: nil # DB の ON DELETE CASCADE で消す
  has_many :transfer_codes, dependent: nil

  normalizes :name, with: ->(name) { name.strip.presence }

  validates :name, length: { maximum: NAME_MAX_LENGTH }, allow_nil: true

  # 家族に入らないまま、30日使われていない利用者(design.md 4.7 の 7)
  scope :abandoned, -> {
    threshold = Time.current - ABANDONED_AFTER
    where.missing(:membership)
      .where(created_at: ...threshold)
      .where.not(id: Session.where(last_used_at: threshold..).select(:user_id))
  }
end
