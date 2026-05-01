require "application_system_test_case"

module Api; end

class Api::TenantsTest < ApplicationSystemTestCase
  test "index returns tenants; show returns tenant detail" do
    sign_in_as("5550000030")
    create_property(name: "API Tenant House", address: "1 Tenant Way")
    create_applicant(name: "API Tenant", mobile: "5550000031", summary: "Renter.", property_address: "1 Tenant Way")
    create_lease_for("API Tenant", rent: "1000", start_date: "2026-01-01")
    api_token = mint_api_token
    click_on "Log out"

    visit "/tenants.json"
    assert_match %r{"error"}, page.body

    page.driver.header("Authorization", "Bearer #{api_token}")
    visit "/tenants.json"
    body = JSON.parse(page.body)
    assert body["tenants"].is_a?(Array)
    tenant = body["tenants"].find { |t| t["name"] == "API Tenant" }
    assert tenant
    assert_equal true, tenant["active?"]

    visit "/tenants/#{tenant['applicant_id']}.json"
    detail = JSON.parse(page.body)["tenant"]
    assert_equal "API Tenant", detail["name"]
  end
end
