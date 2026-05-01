require "test_helper"
require_relative "support/scenarios"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test
  include Scenarios

  setup do
    SmsClient::TestBackend.reset!
    SmsClient.backend = SmsClient::TestBackend
  end
end
