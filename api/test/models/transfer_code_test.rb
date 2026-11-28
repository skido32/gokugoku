require "test_helper"

class TransferCodeTest < ActiveSupport::TestCase
  test "12文字のコードを発行し、平文ではなく HMAC を保存する" do
    transfer_code = TransferCode.issue!(users(:papa))

    assert_match(/\A[2-9A-HJ-NP-Z]{12}\z/, transfer_code.code)
    assert_equal TransferCode.digest(transfer_code.code), transfer_code.reload.code_digest
    assert_not_equal OpenSSL::Digest::SHA256.hexdigest(transfer_code.code), transfer_code.code_digest
  end

  test "有効期限は24時間" do
    freeze_time do
      assert_equal 24.hours.from_now, TransferCode.issue!(users(:papa)).expires_at
    end
  end

  test "コードで、同じ利用者の新しいセッションを作る" do
    code = TransferCode.issue!(users(:papa)).code

    session = TransferCode.redeem!(code)

    assert_equal users(:papa), session.user
    assert session.token.present?
  end

  test "小文字やハイフン入りでも使える" do
    code = TransferCode.issue!(users(:papa)).code

    assert TransferCode.redeem!(code.downcase.scan(/.{4}/).join("-"))
  end

  test "使うと、その利用者の他のセッションはすべて失効する" do
    old_device = Session.start!(users(:papa))
    other_user = Session.start!(users(:mama))
    code = TransferCode.issue!(users(:papa)).code

    new_device = TransferCode.redeem!(code)

    assert_nil Session.authenticate(old_device.token)
    assert_equal new_device, Session.authenticate(new_device.token)
    assert_equal other_user, Session.authenticate(other_user.token)
  end

  test "1回しか使えない" do
    code = TransferCode.issue!(users(:papa)).code

    assert TransferCode.redeem!(code)
    assert_nil TransferCode.redeem!(code)
  end

  test "24時間を過ぎると使えない" do
    freeze_time
    code = TransferCode.issue!(users(:papa)).code

    travel 24.hours - 1.second do
      assert TransferCode.usable.exists?(code_digest: TransferCode.digest(code))
    end
    travel 24.hours do
      assert_nil TransferCode.redeem!(code)
    end
  end

  test "誤ったコードでは使えない" do
    TransferCode.issue!(users(:papa))

    assert_nil TransferCode.redeem!("ABCDEFGHJKLM")
    assert_nil TransferCode.redeem!("")
  end

  test "発行し直すと、古い未使用のコードは使えなくなる" do
    old_code = TransferCode.issue!(users(:papa)).code
    new_code = TransferCode.issue!(users(:papa)).code

    assert_nil TransferCode.redeem!(old_code)
    assert TransferCode.redeem!(new_code)
  end
end
