ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "minitest/mock"
require_relative "test_helpers/session_test_helper"

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def create_care_home(name: "Maison Test", address: "1 rue de Paris", **attributes)
      CareHome.create!(name:, address:, **attributes)
    end

    # A published space whose publication date is `days` from now (negative for the past).
    def create_space(name:, days: -1, care_home: create_care_home, **attributes)
      care_home.spaces.create!(name:, published_at: days.days.from_now, **attributes)
    end

    def create_address(**attributes)
      Address.create!(raw_address: "Adresse #{SecureRandom.hex(4)}", **attributes)
    end
  end
end
