require "application_system_test_case"

module Api; end

class Api::LeasesTest < ApplicationSystemTestCase
  test "leases.json returns rent-roll entries with totals" do
    sign_in_as("5550000050")
    create_property(name: "Roll API House", address: "1 Roll Way")
    create_applicant(name: "Roll API Tenant", mobile: "5550000051", summary: "Renter.", property_address: "1 Roll Way")
    create_lease_for("Roll API Tenant", rent: "1500", start_date: "2026-01-01")
    api_token = mint_api_token
    click_on "Log out"

    visit "/leases.json"
    assert_match %r{"error"}, page.body

    page.driver.header("Authorization", "Bearer #{api_token}")
    visit "/leases.json"
    body = JSON.parse(page.body)
    assert body["entries"].is_a?(Array)
    entry = body["entries"].first
    assert_equal 150000, entry["rent_cents"]
    assert_equal 150000, entry["total_cents"]
    assert entry["next_due_on"]
  end
end
