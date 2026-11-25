require "test_helper"

class MembershipTest < ActiveSupport::TestCase
  test "利用者は1つの家族にだけ所属できる(DB の一意制約)" do
    membership = Membership.new(user: users(:papa), family: families(:others), role: :member)

    assert_raises(ActiveRecord::RecordNotUnique) do
      membership.save!(validate: false)
    end
  end

  test "家族の利用者は6人まで" do
    family = families(:ours)
    4.times { |i| Membership.create!(user: User.create!(name: "親#{i}"), family:, role: :member) }
    assert_equal Family::MAX_MEMBERS, family.memberships.count

    seventh = Membership.new(user: users(:newcomer), family:, role: :member)

    assert_not seventh.valid?
    assert seventh.errors.added?(:family, :full, count: Family::MAX_MEMBERS)
  end

  test "役割は owner か member だけ" do
    membership = Membership.new(user: users(:newcomer), family: families(:others), role: "admin")

    assert_not membership.valid?
  end
end
