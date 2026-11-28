require "test_helper"

class SessionTest < ActiveSupport::TestCase
  test "トークンの平文は保存せず、SHA-256 だけを保存する" do
    session = Session.start!(users(:papa))

    assert_equal 43, session.token.length # 256ビットの Base64URL
    assert_equal Session.digest(session.token), session.reload.token_digest
    assert_not_includes Session.pluck(:token_digest), session.token
    assert_nil Session.find(session.id).token
  end

  test "トークンで認証できる。失効したら認証できない" do
    session = Session.start!(users(:papa))

    assert_equal session, Session.authenticate(session.token)

    session.revoke!
    assert_nil Session.authenticate(session.token)
  end

  test "空・誤りのトークンでは認証できない" do
    assert_nil Session.authenticate(nil)
    assert_nil Session.authenticate("")
    assert_nil Session.authenticate("wrong")
  end

  test "時間が経っても切れない" do
    session = Session.start!(users(:papa))

    travel 3.years do
      assert_equal session, Session.authenticate(session.token)
    end
  end

  test "最終利用時刻は、1日1回だけ更新する" do
    session = nil
    travel_to Time.zone.parse("2026-11-28T00:00:00Z") do
      session = Session.start!(users(:papa))
    end

    travel_to Time.zone.parse("2026-11-28T23:00:00Z") do
      Session.authenticate(session.token)
      assert_equal Time.zone.parse("2026-11-28T00:00:00Z"), session.reload.last_used_at
    end

    travel_to Time.zone.parse("2026-11-29T00:00:00Z") do
      Session.authenticate(session.token)
      assert_equal Time.zone.parse("2026-11-29T00:00:00Z"), session.reload.last_used_at
    end
  end

  test "利用者を削除すると、セッションも消える" do
    session = Session.start!(users(:papa))

    users(:papa).destroy!

    assert_not Session.exists?(session.id)
  end
end
