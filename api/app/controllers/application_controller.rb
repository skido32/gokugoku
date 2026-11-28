class ApplicationController < ActionController::API
  include Authentication

  rescue_from ActiveRecord::RecordNotFound, with: -> { render_error :not_found, "not_found" }
  rescue_from ActionController::ParameterMissing do |error|
    render_error :unprocessable_content, "validation_failed", details: { error.param => [ "is missing" ] }
  end
  rescue_from ActiveRecord::RecordInvalid do |error|
    render_error :unprocessable_content, "validation_failed", details: error.record.errors.to_hash
  end

  private
    # エラーの形式は design.md 3.1
    def render_error(status, code, message: nil, details: nil)
      body = { code:, message: message || Rack::Utils::HTTP_STATUS_CODES[Rack::Utils.status_code(status)] }
      body[:details] = details if details
      render json: { error: body }, status:
    end

    def render_rate_limited
      render_error :too_many_requests, "rate_limited"
    end
end
