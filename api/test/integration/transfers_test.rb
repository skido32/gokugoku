require "test_helper"

class TransfersTest < ActionDispatch::IntegrationTest
  test "古い端末でコードを発行し、新しい端末で引き継ぐと、古い端末は 401 になる" do
    old_device = auth_headers(users(:papa))

    post "/v1/transfer_codes", headers: old_device
    assert_response :created
    code = response.parsed_body["code"]
    assert response.parsed_body["expires_at"]

    post "/v1/transfers", params: { code: }, as: :json
    assert_response :created
    new_device = { "Authorization" => "Bearer #{response.parsed_body["token"]}" }
    assert_equal users(:papa).id, response.parsed_body.dig("user", "id")

    get "/v1/me", headers: new_device
    assert_response :ok
    assert_equal families(:ours).id, response.parsed_body.dig("family", "id")

    get "/v1/me", headers: old_device
    assert_response :unauthorized
  end

  test "使用済み・期限切れ・誤りのコードは、同じ 422 で拒否する" do
    used = TransferCode.issue!(users(:papa)).code
    TransferCode.redeem!(used)
    expired = TransferCode.issue!(users(:mama)).code

    travel 25.hours do
      [ used, expired, "ABCDEFGHJKLM" ].each do |code|
        post "/v1/transfers", params: { code: }, as: :json
        assert_response :unprocessable_content
        assert_equal "invalid_code", response.parsed_body.dig("error", "code")
      end
    end
  end

  test "コードの入力は、同じ IP から10分に5回まで" do
    5.times do
      post "/v1/transfers", params: { code: "ABCDEFGHJKLM" }, as: :json
      assert_response :unprocessable_content
    end

    code = TransferCode.issue!(users(:papa)).code
    post "/v1/transfers", params: { code: }, as: :json
    assert_response :too_many_requests
  end

  test "コードの発行には認証が要る" do
    post "/v1/transfer_codes"

    assert_response :unauthorized
  end
end
