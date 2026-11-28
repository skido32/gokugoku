# 引き継ぎコードで、新しい端末のセッションを作る(F-AUTH-3, design.md 4.7 の 4)
class V1::TransfersController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 5, within: 10.minutes, with: -> { render_rate_limited } # 総当たりを防ぐ(F-AUTH-5)

  def create
    session = TransferCode.redeem!(params.expect(:code))

    # 誤り・期限切れ・使用済みを区別しない(どれに当たったかを推測させない)
    if session.nil?
      render_error :unprocessable_content, "invalid_code"
    else
      render json: { token: session.token, user: { id: session.user.id, name: session.user.name } }, status: :created
    end
  end
end
