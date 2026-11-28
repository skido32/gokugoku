require "test_helper"

class FamilyTest < ActiveSupport::TestCase
  test "既定のタイムゾーンは Asia/Tokyo" do
    assert_equal "Asia/Tokyo", Family.create!(name: "新しい家族").time_zone
  end

  test "家族名は必須で、30文字まで" do
    assert_not Family.new(name: "  ").valid?
    assert Family.new(name: "あ" * 30).valid?
    assert_not Family.new(name: "あ" * 31).valid?
  end

  test "タイムゾーンは IANA の名前だけを受け付ける" do
    assert Family.new(name: "家", time_zone: "America/New_York").valid?
    assert_not Family.new(name: "家", time_zone: "Tokyo").valid?
    assert_not Family.new(name: "家", time_zone: "Mars/Olympus").valid?
  end

  test "子どもは並び順で返す" do
    assert_equal %w[あお もも], families(:ours).children.map(&:name)
  end

  test "家族を削除すると、所属・子ども・記録がすべて消え、利用者は残る" do
    family = families(:ours)

    family.destroy!

    assert_equal 0, Membership.where(family_id: family.id).count
    assert_equal 0, Child.where(family_id: family.id).count
    assert_equal 0, FeedingEvent.where(family_id: family.id).count
    assert User.exists?(users(:papa).id)
  end
end
