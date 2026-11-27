class Family < ApplicationRecord
  NAME_MAX_LENGTH = 30
  MAX_MEMBERS = 6 # F-FAM-4
  FEEDING_KINDS = %w[formula breast].freeze

  has_many :memberships, dependent: nil # 子テーブルは DB の ON DELETE CASCADE で消す
  has_many :users, through: :memberships
  has_many :children, -> { order(:position) }, dependent: nil, inverse_of: :family
  has_many :feeding_events, dependent: nil

  normalizes :name, with: ->(name) { name.strip }

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :time_zone, inclusion: { in: ->(_) { TZInfo::Timezone.all_identifiers } }
  validates :default_feeding_kind, inclusion: { in: FEEDING_KINDS }
end
