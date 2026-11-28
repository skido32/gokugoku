class V1::SessionsController < ApplicationController
  # 自分の他の端末のセッションを、すべて失効させる(F-AUTH-2)
  def destroy_others
    now = Time.current
    current_user.sessions.active.where.not(id: Current.session.id).update_all(revoked_at: now, updated_at: now)
    head :no_content
  end
end
