class User < ApplicationRecord
  NAME_MAX_LENGTH = 20

  has_one :membership, dependent: nil # DB の ON DELETE CASCADE で消す
  has_one :family, through: :membership

  normalizes :name, with: ->(name) { name.strip.presence }

  validates :name, length: { maximum: NAME_MAX_LENGTH }, allow_nil: true
end
