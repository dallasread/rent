require "application_system_test_case"

class PropertiesTest < ApplicationSystemTestCase
  test "create, edit, duplicate, delete a property" do
    sign_in("5551234567")

    visit "/properties"
    assert_text "No properties yet"

    click_on "Add property"
    fill_in "name", with: "Beachfront Cottage"
    fill_in "beds", with: 3
    fill_in "baths", with: 2
    fill_in "description", with: "Steps from the sand."
    click_on "Create"

    assert_text "Property added"
    assert_text "Beachfront Cottage"
    assert_link "beachfront-cottage"

    click_on "Edit"
    fill_in "name", with: "Beachfront Cottage (renovated)"
    click_on "Save"

    assert_text "Property updated"
    assert_text "Beachfront Cottage (renovated)"

    click_on "Duplicate"
    assert_text "Property duplicated"
    assert_field "name", with: "Beachfront Cottage (renovated) (copy)"
    click_on "Cancel"

    assert_text "Beachfront Cottage (renovated) (copy)"
    assert_link "beachfront-cottage-renovated-copy"

    all("button", text: "Delete").last.click
    assert_text "Property removed"
    assert_no_text "(copy)"
  end

  test "name is required" do
    sign_in("5559876543")
    visit "/properties/new"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"
    assert_text "Name is required"
  end

  test "permalink can be edited" do
    sign_in("5553334444")
    visit "/properties/new"
    fill_in "name", with: "Sunset View"
    fill_in "beds", with: 2
    fill_in "baths", with: 1
    click_on "Create"

    assert_link "sunset-view"
    click_on "Edit"
    fill_in "permalink", with: "ocean-loft"
    click_on "Save"

    assert_link "ocean-loft"
    assert_no_link "sunset-view"

    visit "/properties/ocean-loft"
    assert_text "Sunset View"
  end

  test "publish and unpublish a property" do
    sign_in("5557778888")
    visit "/properties/new"
    fill_in "name", with: "Hilltop Studio"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"

    assert_text "Draft"
    assert_no_text "Accepting applications"

    click_on "Publish"
    assert_text "Property published"
    assert_text "Accepting applications"

    click_on "Unpublish"
    assert_text "Property unpublished"
    assert_text "Draft"
  end

  test "published property is publicly visible; unpublished is not" do
    sign_in("5551112222")
    visit "/properties/new"
    fill_in "name", with: "Public Listing"
    fill_in "beds", with: 2
    fill_in "baths", with: 1
    fill_in "description", with: "Open to all."
    click_on "Create"
    click_on "Publish"
    click_on "Log out"
    assert_text "Log in"

    # Published — public can see, no edit link
    visit "/properties/public-listing"
    assert_text "Public Listing"
    assert_text "Open to all."
    assert_no_link "Edit this property"

    # Logged-in users still see edit link
    sign_in("5551112222")
    visit "/properties/public-listing"
    assert_link "Edit this property"

    # Unpublish — public can't see anymore, redirected to login
    click_on "Properties"
    click_on "Unpublish"
    click_on "Log out"
    visit "/properties/public-listing"
    assert_no_text "Public Listing"
    assert_text "Property not found"
  end

  test "public can apply to a published property; admins see applicants" do
    sign_in("5552223333")
    visit "/properties/new"
    fill_in "name", with: "Lisgar Loft"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"
    click_on "Publish"
    click_on "Log out"

    visit "/properties/lisgar-loft"
    click_on "Apply for this property"
    fill_in "name", with: "Jane Renter"
    fill_in "mobile", with: "5559998888"
    fill_in "summary", with: "Quiet remote worker, 2 cats."
    click_on "Submit application"

    assert_text "Application received"

    sign_in("5552223333")
    click_on "Applicants"
    assert_text "Jane Renter"
    assert_text "5559998888"
    assert_text "Lisgar Loft"

    click_on "Jane Renter"
    assert_text "Mobile:"
    assert_text "5559998888"
    assert_text "Quiet remote worker, 2 cats"
    click_on "← All applicants"
    assert_text "Applicants"
  end

  test "cannot apply to unpublished property" do
    sign_in("5554445555")
    visit "/properties/new"
    fill_in "name", with: "Hidden Cabin"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"
    click_on "Log out"

    visit "/properties/hidden-cabin/apply"
    assert_text "Property not found"
  end

  test "admin can add an adhoc applicant, optionally tied to a property" do
    sign_in("5556661111")
    visit "/properties/new"
    fill_in "name", with: "Harbor House"
    fill_in "beds", with: 2
    fill_in "baths", with: 1
    click_on "Create"

    visit "/applicants/new"
    fill_in "name", with: "Walk-in Wanda"
    fill_in "mobile", with: "5550001111"
    fill_in "summary", with: "Showed up at the door."
    select "Harbor House", from: "property_id"
    click_on "Add applicant"

    assert_text "Applicant added"
    assert_text "Walk-in Wanda"
    assert_text "Harbor House"

    visit "/applicants/new"
    fill_in "name", with: "Adhoc Adam"
    fill_in "mobile", with: "5550002222"
    fill_in "summary", with: "Just inquiring."
    click_on "Add applicant"

    assert_text "Applicant added"
    assert_text "Adhoc Adam"
    assert_text "(adhoc)"
  end

  test "create a lease from an applicant; reject overlapping lease" do
    sign_in("5557770000")
    visit "/properties/new"
    fill_in "name", with: "Marina Flat"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"
    click_on "Publish"

    visit "/properties/marina-flat"
    click_on "Apply for this property"
    fill_in "name", with: "Tenant One"
    fill_in "mobile", with: "5559001111"
    fill_in "summary", with: "Sailor."
    click_on "Submit application"

    click_on "Applicants"
    click_on "Tenant One"
    click_on "Create lease"
    fill_in "start_date", with: "2026-06-01"
    fill_in "end_date", with: "2027-05-31"
    click_on "Create lease"

    assert_text "Lease created"
    assert_text "Marina Flat"
    assert_text "Tenant One"

    # Add a second applicant for the same property and try to overlap
    visit "/applicants/new"
    fill_in "name", with: "Tenant Two"
    fill_in "mobile", with: "5559002222"
    fill_in "summary", with: "Conflicts."
    select "Marina Flat", from: "property_id"
    click_on "Add applicant"

    click_on "Tenant Two"
    click_on "Create lease"
    fill_in "start_date", with: "2026-12-01"
    fill_in "end_date", with: "2027-11-30"
    click_on "Create lease"

    assert_text "Lease overlaps"
  end

  test "admins see address; public sees marketing name" do
    sign_in("5559001000")
    visit "/properties/new"
    fill_in "name", with: "Charming Beachfront Cottage"
    fill_in "address", with: "22 Lisgar Street"
    fill_in "beds", with: 2
    fill_in "baths", with: 1
    click_on "Create"
    click_on "Publish"

    # Admin index shows address column
    assert_text "22 Lisgar Street"

    # Logged out — public sees the marketing name, not the address
    click_on "Log out"
    visit "/properties/charming-beachfront-cottage"
    assert_text "Charming Beachfront Cottage"
    assert_no_text "22 Lisgar Street"

    # Logged-in admin viewing the same page sees the address line
    sign_in("5559001000")
    visit "/properties/charming-beachfront-cottage"
    assert_text "Charming Beachfront Cottage"
    assert_text "22 Lisgar Street"
  end

  test "record a transaction on a lease and mark it paid" do
    sign_in("5558881111")
    visit "/properties/new"
    fill_in "name", with: "Cliffside Cabin"
    fill_in "address", with: "5 Cliff Road"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"

    visit "/applicants/new"
    fill_in "name", with: "Tx Tenant"
    fill_in "mobile", with: "5550009999"
    fill_in "summary", with: "Test."
    select "5 Cliff Road", from: "property_id"
    click_on "Add applicant"

    click_on "Tx Tenant"
    click_on "Create lease"
    fill_in "start_date", with: "2026-06-01"
    click_on "Create lease"

    click_on "Tx Tenant"  # link in the leases table
    click_on "Record transaction"
    fill_in "description", with: "June rent"
    fill_in "amount", with: "1500"
    fill_in "method", with: "e-transfer"
    uncheck "Mark as paid now"
    click_on "Record"

    assert_text "Transaction recorded"
    assert_text "June rent"
    assert_text "$1500.00"
    assert_text "Pending"

    click_on "June rent"
    click_on "Mark paid"
    assert_text "Marked paid"
    assert_text "Paid"
    assert_no_text "Pending"
  end

  test "non-admin cannot access admin pages" do
    sign_in("5550000001")  # first login → admin
    click_on "Log out"

    sign_in("5550000002")  # second login → non-admin
    assert_no_link "Properties"

    visit "/properties"
    assert_text "Admin access required"

    visit "/properties/new"
    assert_text "Admin access required"
  end

  private

  def sign_in(mobile)
    visit "/login"
    fill_in "mobile", with: mobile
    click_on "Send code"
    code = SmsClient::TestBackend.messages.last[:body][/\d{6}/]
    fill_in "code", with: code
    click_on "Log in"
    assert_text "Dashboard"
  end
end
