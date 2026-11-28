require "test_helper"

class FeedingEventTest < ActiveSupport::TestCase
  def build_event(**attrs)
    FeedingEvent.new(
      family: families(:ours),
      child: children(:elder),
      recorded_by: users(:papa),
      fed_at: Time.current,
      kind: :formula,
      operation_id: SecureRandom.uuid,
      client_request_id: SecureRandom.uuid,
      **attrs
    )
  end

  test "必要な値がそろえば作れる" do
    assert build_event.save
  end

  test "作成時は記録者が必須" do
    assert_not build_event(recorded_by: nil).valid?
  end

  test "量は任意で、0〜500ml の整数" do
    assert build_event(amount_ml: nil).valid?
    assert build_event(amount_ml: 0).valid?
    assert build_event(amount_ml: 500).valid?
    assert_not build_event(amount_ml: 501).valid?
    assert_not build_event(amount_ml: -1).valid?
    assert_not build_event(amount_ml: 10.5).valid?
  end

  test "DB でも、量の範囲を守る" do
    assert_raises(ActiveRecord::StatementInvalid) do
      build_event(amount_ml: 501).save!(validate: false)
    end
  end

  test "種類はミルク・母乳・混合だけ" do
    assert build_event(kind: :mixed, amount_ml: 40).valid?
    assert_not build_event(kind: "juice").valid?
  end

  test "DB でも、種類を守る" do
    event = build_event
    event.kind = :formula
    event.save!

    assert_raises(ActiveRecord::StatementInvalid) do
      event.update_column(:kind, "juice")
    end
  end

  test "ミルクと混合は、量がなくても記録できる" do
    assert build_event(kind: :formula, amount_ml: nil).save
    assert build_event(kind: :mixed, amount_ml: nil).save
  end

  test "母乳は量を持たない(送られても空にする)" do
    event = build_event(kind: :breast, amount_ml: 100)
    event.save!

    assert_nil event.reload.amount_ml
  end

  test "母乳に変えると、量は空になる" do
    event = feeding_events(:elder_morning)

    event.update!(kind: :breast)

    assert_nil event.reload.amount_ml
  end

  test "DB でも、母乳の記録に量を持たせない" do
    event = feeding_events(:elder_morning)

    assert_raises(ActiveRecord::StatementInvalid) do
      event.update_columns(kind: "breast")
    end
  end

  test "他の家族の子どもには記録できない" do
    event = build_event(child: children(:others_child))

    assert_not event.valid?
    assert event.errors.added?(:child, :invalid)
  end

  test "DB の複合外部キーでも、他の家族の子どもへの記録を防ぐ" do
    event = build_event(child: children(:others_child))

    assert_raises(ActiveRecord::InvalidForeignKey) do
      event.save!(validate: false)
    end
  end

  test "同じ家族・同じ冪等性キー・同じ子どもの記録は、DB で1件に限られる" do
    original = feeding_events(:elder_morning)
    duplicate = build_event(client_request_id: original.client_request_id)

    assert_raises(ActiveRecord::RecordNotUnique) do
      duplicate.save!(validate: false)
    end
  end

  test "論理削除した記録も、冪等性キーの対象になる(再送で記録が復活しない)" do
    original = feeding_events(:elder_morning)
    original.update!(deleted_at: Time.current)

    assert_raises(ActiveRecord::RecordNotUnique) do
      build_event(client_request_id: original.client_request_id).save!(validate: false)
    end
  end

  test "「全員」の記録は、同じ冪等性キーで子どもごとに作れる" do
    operation_id = SecureRandom.uuid

    assert_difference -> { FeedingEvent.count }, 2 do
      build_event(child: children(:elder), operation_id:, client_request_id: "req-all").save!
      build_event(child: children(:younger), operation_id:, client_request_id: "req-all").save!
    end
  end

  test "active は論理削除した記録を除く" do
    deleted = build_event(deleted_at: Time.current)
    deleted.save!

    assert_includes FeedingEvent.active, feeding_events(:elder_morning)
    assert_not_includes FeedingEvent.active, deleted
    assert deleted.deleted?
  end

  test "記録者を削除しても、記録は残り、記録者は空になる" do
    event = feeding_events(:elder_morning)

    users(:papa).destroy!

    assert_nil event.reload.recorded_by_id
    assert event.valid?
  end

  test "時刻は UTC で保存し、タイムゾーンつきで読み戻せる" do
    fed_at = Time.zone.parse("2026-11-26T09:30:00+09:00")
    event = build_event(fed_at:)
    event.save!

    assert_equal fed_at, event.reload.fed_at
    assert_equal "timestamp with time zone", FeedingEvent.columns_hash["fed_at"].sql_type
  end
end
