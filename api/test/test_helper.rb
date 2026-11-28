ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    # rate_limit の回数を、テストごとに消す
    setup { Rails.cache.clear }
  end
end

module ActionDispatch
  class IntegrationTest
    def auth_headers(user = users(:papa))
      { "Authorization" => "Bearer #{::Session.start!(user).token}" }
    end
  end
end
