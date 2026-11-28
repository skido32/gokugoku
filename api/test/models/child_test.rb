require "test_helper"

class ChildTest < ActiveSupport::TestCase
  test "使われていない色と位置を、順に割り当てる" do
    third = families(:ours).children.create!(name: "みどり")

    assert_equal "green", third.color
    assert_equal 2, third.position
  end

  test "空いた位置を埋める" do
    children(:elder).destroy!

    child = families(:ours).children.create!(name: "あたらしい子")

    assert_equal 0, child.position
    assert_equal "blue", child.color
  end

  test "名前は必須で、20文字まで" do
    family = families(:ours)

    assert_not family.children.build(name: " ").valid?
    assert family.children.build(name: "あ" * 20).valid?
    assert_not family.children.build(name: "あ" * 21).valid?
  end

  test "いつもの種類の既定はミルクで、ミルク・母乳・混合から選べる" do
    child = families(:ours).children.create!(name: "みどり")

    assert_equal "formula", child.default_feeding_kind
    %w[breast mixed].each do |kind|
      child.default_feeding_kind = kind
      assert child.valid?, kind
    end
  end

  test "いつもの種類は、決められた値だけ(DB でも守る)" do
    child = children(:elder)
    child.default_feeding_kind = "juice"

    assert_not child.valid?
    assert_raises(ActiveRecord::StatementInvalid) do
      child.save!(validate: false)
    end
  end

  test "色は決められた名前だけ" do
    child = children(:elder)
    child.color = "#ff0000"

    assert_not child.valid?
  end

  test "子どもは4人まで" do
    family = families(:ours)
    2.times { |i| family.children.create!(name: "子#{i}") }

    fifth = family.children.build(name: "5人目")

    assert_not fifth.valid?
    assert fifth.errors.added?(:family, :too_many_children, count: Child::MAX_PER_FAMILY)
  end

  test "DB でも、位置は 0〜3 に限られ、4人を超えられない" do
    child = families(:ours).children.build(name: "5人目", color: "green", position: 4)

    assert_raises(ActiveRecord::StatementInvalid) do
      child.save!(validate: false)
    end
  end

  test "同じ家族で位置は重複できない" do
    child = families(:ours).children.build(name: "重複", color: "green", position: 0)

    assert_raises(ActiveRecord::RecordNotUnique) do
      Child.transaction do
        child.save!(validate: false)
        # 一意制約は遅延評価なので、ここで検証させる
        Child.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
      end
    end
  end

  test "並べ替えでは、トランザクションの中で位置を入れ替えられる" do
    elder, younger = children(:elder), children(:younger)

    Child.transaction do
      elder.update!(position: 1)
      younger.update!(position: 0)
      Child.connection.execute("SET CONSTRAINTS ALL IMMEDIATE")
    end

    assert_equal %w[もも あお], families(:ours).children.reload.map(&:name)
  end

  test "子どもを削除すると、その子の記録も消える(F-CHILD-4)" do
    assert_difference -> { FeedingEvent.count }, -1 do
      children(:elder).destroy!
    end
  end
end
