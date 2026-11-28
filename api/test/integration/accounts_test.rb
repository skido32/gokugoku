require "test_helper"

class AccountsTest < ActionDispatch::IntegrationTest
  test "入力なしで利用者を作り、トークンを返す" do
    assert_difference -> { User.count } => 1, -> { Session.count } => 1 do
      post "/v1/accounts"
    end

    assert_response :created
    token = response.parsed_body["token"]
    assert_nil response.parsed_body.dig("user", "name")

    get "/v1/me", headers: { "Authorization" => "Bearer #{token}" }
    assert_response :ok
    assert_nil response.parsed_body["family"]
  end

  test "作るときに、放置された利用者を消す" do
    abandoned = travel_to(31.days.ago) { User.create! }

    post "/v1/accounts"

    assert_not User.exists?(abandoned.id)
  end

  test "同じ IP からは1時間に10回まで" do
    10.times do
      post "/v1/accounts"
      assert_response :created
    end

    post "/v1/accounts"
    assert_response :too_many_requests
    assert_equal "rate_limited", response.parsed_body.dig("error", "code")

    travel 1.hour + 1.second do
      post "/v1/accounts"
      assert_response :created
    end
  end
end
