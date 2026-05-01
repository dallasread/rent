require "application_system_test_case"

module Api; end

class Api::PropertiesTest < ApplicationSystemTestCase
  test "bearer auth gates access; index returns properties" do
    api_token = setup_admin_with_token_and_property("5550000020", "API Sample", "1 Token Way")

    # No bearer → 401
    visit "/properties.json"
    assert_match %r{"error"}, page.body

    # Valid bearer → 200 + properties array
    page.driver.header("Authorization", "Bearer #{api_token}")
    visit "/properties.json"
    body = JSON.parse(page.body)
    assert body["properties"].is_a?(Array)
    assert body["properties"].any? { |p| p["name"] == "API Sample" }

    # Bogus bearer → 401
    page.driver.header("Authorization", "Bearer not-a-real-token")
    visit "/properties.json"
    assert_match %r{"error"}, page.body
  end

  private

  def setup_admin_with_token_and_property(mobile, property_name, property_address)
    visit "/login"
    fill_in "mobile", with: mobile
    click_on "Send code"
    code = SmsClient::TestBackend.messages.last[:body][/\d{6}/]
    fill_in "code", with: code
    click_on "Log in"

    visit "/properties/new"
    fill_in "name", with: property_name
    fill_in "address", with: property_address
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"

    click_on "API tokens"
    click_on "New token"
    fill_in "name", with: "tester"
    click_on "Create"
    token = find("div.flash-notice code").text

    click_on "Log out"
    token
  end
end
