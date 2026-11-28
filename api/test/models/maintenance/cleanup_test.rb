require "test_helper"

class Maintenance::CleanupTest < ActiveSupport::TestCase
  def create_event(**attrs)
    FeedingEvent.create!(
      family: families(:ours), child: children(:elder), recorded_by: users(:papa),
      fed_at: Time.current, kind: :formula, operation_id: SecureRandom.uuid,
      client_request_id: SecureRandom.uuid, **attrs
    )
  end

  test "90日を過ぎた授乳記録を消し、90日以内は残す" do
    freeze_time
    expired = create_event(fed_at: 90.days.ago - 1.second)
    boundary = create_event(fed_at: 90.days.ago)

    Maintenance::Cleanup.call

    assert_not FeedingEvent.exists?(expired.id)
    assert FeedingEvent.exists?(boundary.id)
    assert FeedingEvent.exists?(feeding_events(:elder_morning).id)
  end

  test "記録をやめた家族の記録も消す(書き込みがなくても保持期間を守る)" do
    freeze_time
    others = FeedingEvent.create!(
      family: families(:others), child: children(:others_child), recorded_by: users(:other_parent),
      fed_at: 91.days.ago, kind: :breast, operation_id: SecureRandom.uuid, client_request_id: "old"
    )

    Maintenance::Cleanup.call

    assert_not FeedingEvent.exists?(others.id)
  end

  test "論理削除から24時間を過ぎた記録を消す" do
    freeze_time
    old_deleted = create_event(deleted_at: 24.hours.ago - 1.second)
    recent_deleted = create_event(deleted_at: 24.hours.ago)

    Maintenance::Cleanup.call

    assert_not FeedingEvent.exists?(old_deleted.id)
    assert FeedingEvent.exists?(recent_deleted.id)
  end

  test "失効したセッションを消し、使えるセッションは残す" do
    revoked = Session.start!(users(:papa)).tap(&:revoke!)
    active = Session.start!(users(:papa))

    Maintenance::Cleanup.call

    assert_not Session.exists?(revoked.id)
    assert Session.exists?(active.id)
  end

  test "使用済み・期限切れの引き継ぎコードを消し、使えるコードは残す" do
    used = TransferCode.issue!(users(:papa)).tap { |code| TransferCode.redeem!(code.code) }
    expired = travel_to(25.hours.ago) { TransferCode.issue!(users(:mama)) }
    usable = TransferCode.issue!(users(:other_parent))

    Maintenance::Cleanup.call

    assert_not TransferCode.exists?(used.id)
    assert_not TransferCode.exists?(expired.id)
    assert TransferCode.exists?(usable.id)
  end

  test "放置された利用者を消す" do
    abandoned = travel_to(31.days.ago) { User.create! }

    Maintenance::Cleanup.call

    assert_not User.exists?(abandoned.id)
    assert User.exists?(users(:papa).id)
  end

  test "消した件数を返し、2回目は何も消さない" do
    create_event(fed_at: 91.days.ago)

    assert_equal 1, Maintenance::Cleanup.call[:feeding_events]
    assert_equal({ feeding_events: 0, sessions: 0, transfer_codes: 0, users: 0 }, Maintenance::Cleanup.call)
  end

  test "件数が多くても、分けて消す" do
    5.times { create_event(fed_at: 91.days.ago) }

    assert_equal 5, Maintenance::Cleanup.call(batch_size: 2)[:feeding_events]
  end
end
