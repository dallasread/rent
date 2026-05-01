require "application_system_test_case"

module Api; end

class Api::TaxesTest < ApplicationSystemTestCase
  test "index returns taxes; show returns tax detail" do
    sign_in_as("5550000040")
    click_on "Taxes"
    click_on "New tax"
    fill_in "name", with: "GST"
    fill_in "rate", with: "5"
    click_on "Create"

    api_token = mint_api_token
    click_on "Log out"

    visit "/taxes.json"
    assert_match %r{"error"}, page.body

    page.driver.header("Authorization", "Bearer #{api_token}")
    visit "/taxes.json"
    body = JSON.parse(page.body)
    tax = body["taxes"].find { |t| t["name"] == "GST" }
    assert tax
    assert_equal 500, tax["rate_bp"]

    visit "/taxes/#{tax['id']}.json"
    detail = JSON.parse(page.body)["tax"]
    assert_equal "GST", detail["name"]
  end
end
