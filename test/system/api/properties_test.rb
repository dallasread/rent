require "application_system_test_case"

module Api; end

class Api::PropertiesTest < ApplicationSystemTestCase
  test "bearer auth gates access; index returns properties" do
    sign_in_as("5550000020")
    create_property(name: "API Sample", address: "1 Token Way")
    api_token = mint_api_token
    click_on "Log out"

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
end
