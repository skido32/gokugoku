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
end
