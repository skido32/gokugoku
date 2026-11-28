# 機種変更のための引き継ぎコードを発行する(F-AUTH-3)
class V1::TransferCodesController < ApplicationController
  rate_limit to: 10, within: 1.hour, by: -> { current_user.id }, with: -> { render_rate_limited }

  def create
    transfer_code = TransferCode.issue!(current_user)
    render json: { code: transfer_code.code, expires_at: transfer_code.expires_at }, status: :created
  end
end
