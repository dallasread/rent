require "application_system_test_case"

class LoginTest < ApplicationSystemTestCase
  test "log in, see dashboard, log out" do
    visit "/login"
    assert_text "Log in"

    fill_in "mobile", with: "5551234567"
    click_on "Send code"

    assert_text "Enter your code"
    sms = SmsClient::TestBackend.messages.last
    assert_equal "+15551234567", sms[:to]
    code = sms[:body][/\d{6}/]
    assert code.present?, "expected a 6-digit code in: #{sms[:body]}"

    fill_in "code", with: code
    click_on "Log in"

    assert_text "Dashboard"
    assert_text "+15551234567"

    click_on "Log out"
    assert_text "Log in"
  end

  test "wrong code is rejected and does not log in" do
    visit "/login"
    fill_in "mobile", with: "5559876543"
    click_on "Send code"

    fill_in "code", with: "000000"
    click_on "Log in"

    assert_text "Invalid or expired code"
    assert_no_text "Dashboard"
  end

  test "invalid mobile is rejected" do
    visit "/login"
    fill_in "mobile", with: "not a phone"
    click_on "Send code"

    assert_text "Invalid mobile number"
  end
end
