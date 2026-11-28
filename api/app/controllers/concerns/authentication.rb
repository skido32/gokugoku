# Authorization: Bearer <token> で利用者を特定する(design.md 4.7 の 3)
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private
    def require_authentication
      Current.session = Session.authenticate(bearer_token)
      return if Current.session

      response.headers["WWW-Authenticate"] = "Bearer"
      render_error :unauthorized, "unauthenticated"
    end

    def bearer_token
      request.authorization.to_s[/\ABearer (\S+)\z/, 1]
    end

    def current_user
      Current.user
    end
end
