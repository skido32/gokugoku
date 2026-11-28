require "test_helper"

class AuthenticationTest < ActionDispatch::IntegrationTest
  test "トークンがなければ 401" do
    get "/v1/me"

    assert_response :unauthorized
    assert_equal "unauthenticated", response.parsed_body.dig("error", "code")
    assert_equal "Bearer", response.headers["WWW-Authenticate"]
  end

  test "誤ったトークン・Bearer 以外の形式では 401" do
    get "/v1/me", headers: { "Authorization" => "Bearer wrong" }
    assert_response :unauthorized

    token = Session.start!(users(:papa)).token
    get "/v1/me", headers: { "Authorization" => "Token #{token}" }
    assert_response :unauthorized
  end

  test "失効したセッションでは 401" do
    session = Session.start!(users(:papa))
    session.revoke!

    get "/v1/me", headers: { "Authorization" => "Bearer #{session.token}" }

    assert_response :unauthorized
  end

  test "他の端末のセッションだけを失効させる" do
    current = Session.start!(users(:papa))
    other_device = Session.start!(users(:papa))
    partner = Session.start!(users(:mama))

    delete "/v1/sessions/others", headers: { "Authorization" => "Bearer #{current.token}" }

    assert_response :no_content
    assert_nil Session.authenticate(other_device.token)
    assert Session.authenticate(current.token)
    assert Session.authenticate(partner.token)
  end
end
