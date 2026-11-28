require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "呼び名は未入力でもよい(初回起動の直後)" do
    assert User.new.valid?
  end

  test "呼び名の前後の空白を除き、空白だけなら未入力として扱う" do
    assert_equal "パパ", User.new(name: "  パパ ").name
    assert_nil User.new(name: "   ").name
  end

  test "呼び名は20文字まで" do
    assert User.new(name: "あ" * 20).valid?
    assert_not User.new(name: "あ" * 21).valid?
  end

  test "利用者を削除すると、所属も消える" do
    assert_difference -> { Membership.count }, -1 do
      users(:mama).destroy!
    end
  end

  test "家族に入らないまま30日使われていない利用者だけを、放置された利用者とみなす" do
    abandoned, recently_used, in_family = travel_to(31.days.ago) do
      [ User.create!, User.create!.tap { |user| Session.start!(user) }, users(:papa) ]
    end
    Session.where(user: recently_used).update_all(last_used_at: 1.day.ago)
    brand_new = User.create!

    result = User.abandoned

    assert_includes result, abandoned
    assert_not_includes result, recently_used
    assert_not_includes result, in_family
    assert_not_includes result, brand_new
  end
end
