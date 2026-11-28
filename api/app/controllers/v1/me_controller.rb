class V1::MeController < ApplicationController
  def show
    render json: me_json
  end

  # 呼び名を設定する(F-FAM-1)
  def update
    current_user.update!(params.expect(user: [ :name ]))
    render json: me_json
  end

  private
    def me_json
      membership = current_user.membership
      {
        user: { id: current_user.id, name: current_user.name },
        family: membership && { id: membership.family_id, name: membership.family.name, role: membership.role }
      }
    end
end
