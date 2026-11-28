# 保持期間を過ぎたデータと、不要になった認証情報を消す(design.md 4.10、ADR 0004)。
# 外からの定期実行(bin/rails maintenance:cleanup)で1日1回動かす。何度流しても結果は同じ。
class Maintenance::Cleanup
  BATCH_SIZE = 1_000

  def self.call(now: Time.current, batch_size: BATCH_SIZE)
    new(now:, batch_size:).call
  end

  def initialize(now:, batch_size:)
    @now = now
    @batch_size = batch_size
  end

  # 消した件数を返す(ログには件数だけを出し、個人情報は出さない)
  def call
    {
      feeding_events: delete_in_batches(expired_feeding_events),
      sessions: delete_in_batches(Session.where.not(revoked_at: nil)),
      transfer_codes: delete_in_batches(TransferCode.where.not(used_at: nil).or(TransferCode.where(expires_at: ..@now))),
      users: delete_in_batches(User.abandoned(now: @now))
    }
  end

  private
    def expired_feeding_events
      FeedingEvent.where(fed_at: ...(@now - FeedingEvent::RETENTION))
        .or(FeedingEvent.where(deleted_at: ...(@now - FeedingEvent::DELETED_GRACE)))
    end

    def delete_in_batches(relation)
      relation.in_batches(of: @batch_size).sum(&:delete_all)
    end
end
