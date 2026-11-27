class Child < ApplicationRecord
  NAME_MAX_LENGTH = 20
  MAX_PER_FAMILY = 4 # F-CHILD-3
  COLORS = %w[blue pink green orange purple yellow].freeze

  belongs_to :family, inverse_of: :children
  has_many :feeding_events, dependent: nil # DB の ON DELETE CASCADE で消す(F-CHILD-4)

  normalizes :name, with: ->(name) { name.strip }

  before_validation :assign_color_and_position, on: :create

  validates :name, presence: true, length: { maximum: NAME_MAX_LENGTH }
  validates :color, inclusion: { in: COLORS }
  validates :position, numericality: { only_integer: true, in: 0...MAX_PER_FAMILY }
  validate :family_has_room, on: :create

  private
    # 家族の中で使われていない色と位置を、順に割り当てる(F-CHILD-2)
    def assign_color_and_position
      return if family.nil?

      siblings = Child.where(family_id: family.id).to_a
      self.color ||= (COLORS - siblings.map(&:color)).first || COLORS[siblings.size % COLORS.size]
      self.position ||= ((0...MAX_PER_FAMILY).to_a - siblings.map(&:position)).first
    end

    def family_has_room
      return if family.nil?

      # DB でも、position の範囲(0〜3)と家族内の一意制約で、4人を超えないことを保証している
      if Child.where(family_id: family.id).count >= MAX_PER_FAMILY
        errors.add(:family, :too_many_children, count: MAX_PER_FAMILY)
      end
    end
end
