require "application_system_test_case"

class LeasesTest < ApplicationSystemTestCase
  # Pins the structure of the lease show page redesign:
  # eyebrow + status badges, kv strip, hero metric, action toolbar,
  # transactions empty state, and the badge for a recorded transaction.
  test "lease show page surfaces summary, actions, and transaction status" do
    sign_in_as("5550000300")
    create_property(name: "Show Page House", address: "30 Show Way")
    create_applicant(name: "Show Tenant", mobile: "5550000301", summary: "Test.", property_address: "30 Show Way")
    create_lease_for("Show Tenant", rent: "1200", start_date: "2026-03-01")

    click_on "Show Tenant"   # tenant name links to lease show

    # Page header: eyebrow + lease name + status badges
    assert_text "Lease"
    assert_text "Active"
    assert_text "Open-ended"   # no end_date set
    assert_no_text "Archived"

    # Hero metric and kv summary
    assert_text "Total monthly"
    assert_text "$1200.00"
    assert_text "Property"
    assert_text "30 Show Way"
    assert_text "Tenant"
    assert_text "Show Tenant"
    assert_text "Term"
    assert_text "2026-03-01 → open"

    # Toolbar actions all present in one row
    assert_button "Edit lease"
    assert_button "Archive"
    assert_link   "History"

    # Empty state for a fresh lease
    assert_text "No transactions recorded for this lease yet."

    # Recording a transaction replaces the empty state with a row + Pending badge
    click_on "Record transaction"
    fill_in "description", with: "March rent"
    fill_in "amount", with: "1200"
    select "e-transfer", from: "method"
    fill_in "kind", with: "rent"
    fill_in "paid_on", with: ""
    click_on "Record"

    assert_text "Transaction recorded"
    assert_no_text "No transactions recorded for this lease yet."
    assert_text "March rent"
    assert_text "$1200.00"
    assert_text "Pending"

    # Archiving swaps the status badge
    click_on "Archive"
    assert_text "Lease archived"
    assert_text "Archived"
    assert_no_text "Active"
  end
end
