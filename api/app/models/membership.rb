class Membership < ApplicationRecord
  belongs_to :user
  belongs_to :family

  enum :role, { owner: "owner", member: "member" }, validate: true

  validate :family_has_room, on: :create

  private
    def family_has_room
      return if family.nil?

      if family.memberships.count >= Family::MAX_MEMBERS
        errors.add(:family, :full, count: Family::MAX_MEMBERS)
      end
    end
end
