require "test_helper"

class MeTest < ActionDispatch::IntegrationTest
  test "自分の情報と、所属する家族を返す" do
    get "/v1/me", headers: auth_headers(users(:papa))

    assert_response :ok
    assert_equal users(:papa).id, response.parsed_body.dig("user", "id")
    assert_equal families(:ours).id, response.parsed_body.dig("family", "id")
    assert_equal memberships(:papa).role, response.parsed_body.dig("family", "role")
  end

  test "呼び名を設定する" do
    patch "/v1/me", params: { user: { name: " パパ " } }, headers: auth_headers(users(:newcomer)), as: :json

    assert_response :ok
    assert_equal "パパ", users(:newcomer).reload.name
  end

  test "呼び名が長すぎると 422" do
    patch "/v1/me", params: { user: { name: "あ" * 21 } }, headers: auth_headers(users(:newcomer)), as: :json

    assert_response :unprocessable_content
    assert_equal "validation_failed", response.parsed_body.dig("error", "code")
    assert response.parsed_body.dig("error", "details", "name")
  end

  test "パラメーターがなければ 422" do
    patch "/v1/me", params: {}, headers: auth_headers, as: :json

    assert_response :unprocessable_content
  end
end
