# 初回起動で、匿名の利用者とセッションを作る(F-AUTH-1, design.md 4.7 の 1)
class V1::AccountsController < ApplicationController
  allow_unauthenticated_access
  rate_limit to: 10, within: 1.hour, with: -> { render_rate_limited }

  def create
    session = User.transaction { Session.start!(User.create!) }
    render json: { token: session.token, user: { id: session.user.id, name: nil } }, status: :created
  end
end
