require "test_helper"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :rack_test

  setup do
    SmsClient::TestBackend.reset!
    SmsClient.backend = SmsClient::TestBackend
  end
end
