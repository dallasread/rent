require "application_system_test_case"

class TenantsTest < ApplicationSystemTestCase
  # Pins the tenant edit flow:
  # name, mobile, and notes are editable; the original applicant summary
  # is preserved as immutable history; both views reflect the new values.
  test "edit tenant updates name, mobile, and notes — applicant summary unchanged" do
    sign_in_as("5550000400")
    create_property(name: "Edit Tenant House", address: "40 Edit Way")
    create_applicant(
      name: "Original Name",
      mobile: "5550000401",
      summary: "Original applicant summary.",
      property_address: "40 Edit Way"
    )
    create_lease_for("Original Name", rent: "1500", start_date: "2026-01-01")

    click_on "Tenants"
    click_on "Original Name"
    click_on "Edit"

    fill_in "name",   with: "Renamed Tenant"
    fill_in "mobile", with: "5550000402"
    fill_in "notes",  with: "Pays on time. Has two cats."
    click_on "Save"

    assert_text "Tenant updated."
    assert_text "Renamed Tenant"
    assert_text "+15550000402"
    assert_text "Pays on time. Has two cats."

    # Applicant page reflects updated identity but still shows the original
    # intake summary plus the new notes block.
    click_on "View application"
    assert_text "Renamed Tenant"
    assert_text "+15550000402"
    assert_text "Original applicant summary."
    assert_text "Pays on time. Has two cats."
  end

  test "edit tenant rejects blank name and invalid mobile" do
    sign_in_as("5550000410")
    create_property(name: "Validation House", address: "41 Validate Way")
    create_applicant(
      name: "Valid Tenant",
      mobile: "5550000411",
      summary: "Test.",
      property_address: "41 Validate Way"
    )
    create_lease_for("Valid Tenant", rent: "1500", start_date: "2026-01-01")

    click_on "Tenants"
    click_on "Valid Tenant"
    click_on "Edit"

    fill_in "name", with: ""
    click_on "Save"
    assert_text "Name is required."

    fill_in "name",   with: "Valid Tenant"
    fill_in "mobile", with: "not-a-number"
    click_on "Save"
    assert_text "Invalid mobile number."
  end
end
