require "application_system_test_case"

class PropertiesTest < ApplicationSystemTestCase
  test "create, edit, duplicate, delete a property" do
    sign_in_as("5551234567")

    visit "/properties"
    assert_text "No properties yet"

    create_property(name: "Beachfront Cottage", address: "1 Sand Way", beds: 3, baths: 2, description: "Steps from the sand.")

    assert_text "Property added"
    assert_text "1 Sand Way"
    assert_link "beachfront-cottage"

    click_on "Edit"
    fill_in "name", with: "Beachfront Cottage (renovated)"
    click_on "Save"

    assert_text "Property updated"

    click_on "Duplicate"
    assert_text "Property duplicated"
    assert_field "name", with: "Beachfront Cottage (renovated) (copy)"
    click_on "Cancel"

    assert_link "beachfront-cottage-renovated-copy"

    all("button", text: "Delete").last.click
    assert_text "Property removed"
    assert_no_text "(copy)"
  end

  test "name is required" do
    sign_in_as("5559876543")
    visit "/properties/new"
    fill_in "beds", with: 1
    fill_in "baths", with: 1
    click_on "Create"
    assert_text "Name is required"
  end

  test "permalink can be edited" do
    sign_in_as("5553334444")
    create_property(name: "Sunset View", address: "2 Hill Road", beds: 2, baths: 1)

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
    sign_in_as("5557778888")
    create_property(name: "Hilltop Studio", address: "3 Peak Lane")

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
    sign_in_as("5551112222")
    create_property(name: "Public Listing", address: "4 Open Way", beds: 2, baths: 1, description: "Open to all.", publish: true)
    click_on "Log out"
    assert_text "Log in"

    visit "/properties/public-listing"
    assert_text "Public Listing"
    assert_text "Open to all."
    assert_no_link "Edit this property"

    sign_in_as("5551112222")
    visit "/properties/public-listing"
    assert_link "Edit this property"

    within("aside") { click_on "Properties" }
    click_on "Unpublish"
    click_on "Log out"
    visit "/properties/public-listing"
    assert_no_text "Public Listing"
    assert_text "Property not found"
  end

  test "public can apply to a published property; admins see applicants" do
    sign_in_as("5552223333")
    create_property(name: "Lisgar Loft", address: "5 Lisgar St", publish: true)
    click_on "Log out"

    public_apply_for("lisgar-loft", name: "Jane Renter", mobile: "5559998888", summary: "Quiet remote worker, 2 cats.")
    assert_text "Application received"

    sign_in_as("5552223333")
    click_on "Applicants"
    assert_text "Jane Renter"
    assert_text "5559998888"
    assert_text "5 Lisgar St"

    click_on "Jane Renter"
    assert_text "Mobile:"
    assert_text "Quiet remote worker, 2 cats"
    click_on "← All applicants"
    assert_text "Applicants"
  end

  test "cannot apply to unpublished property" do
    sign_in_as("5554445555")
    create_property(name: "Hidden Cabin", address: "6 Secret Trail")
    click_on "Log out"

    visit "/properties/hidden-cabin/apply"
    assert_text "Property not found"
  end

  test "admin can add an adhoc applicant, optionally tied to a property" do
    sign_in_as("5556661111")
    create_property(name: "Harbor House", address: "7 Dock Road", beds: 2)

    create_applicant(name: "Walk-in Wanda", mobile: "5550001111", summary: "Showed up at the door.", property_address: "7 Dock Road")
    assert_text "Applicant added"
    assert_text "Walk-in Wanda"
    assert_text "7 Dock Road"

    create_applicant(name: "Adhoc Adam", mobile: "5550002222", summary: "Just inquiring.")
    assert_text "Applicant added"
    assert_text "Adhoc Adam"
    assert_text "(adhoc)"
  end

  test "create a lease from an applicant; reject overlapping lease" do
    sign_in_as("5557770000")
    create_property(name: "Marina Flat", address: "8 Marina Dr", publish: true)

    public_apply_for("marina-flat", name: "Tenant One", mobile: "5559001111", summary: "Sailor.")

    click_on "Applicants"
    create_lease_for("Tenant One", rent: "1500", start_date: "2026-01-01", end_date: "2026-12-31")
    assert_text "Lease created"
    assert_text "8 Marina Dr"
    assert_text "Tenant One"

    create_applicant(name: "Tenant Two", mobile: "5559002222", summary: "Conflicts.", property_address: "8 Marina Dr")
    create_lease_for("Tenant Two", rent: "1500", start_date: "2026-06-01", end_date: "2027-05-31")
    assert_text "Lease overlaps"
  end

  test "admins see address; public sees marketing name" do
    sign_in_as("5559001000")
    create_property(name: "Charming Beachfront Cottage", address: "22 Lisgar Street", beds: 2, baths: 1, publish: true)
    assert_text "22 Lisgar Street"

    click_on "Log out"
    visit "/properties/charming-beachfront-cottage"
    assert_text "Charming Beachfront Cottage"
    assert_no_text "22 Lisgar Street"

    sign_in_as("5559001000")
    visit "/properties/charming-beachfront-cottage"
    assert_text "Charming Beachfront Cottage"
    assert_text "22 Lisgar Street"
  end

  test "record a transaction on a lease and mark it paid" do
    sign_in_as("5558881111")
    create_property(name: "Cliffside Cabin", address: "5 Cliff Road")
    create_applicant(name: "Tx Tenant", mobile: "5550009999", summary: "Test.", property_address: "5 Cliff Road")
    create_lease_for("Tx Tenant", rent: "1500", start_date: "2026-01-01")

    click_on "Tx Tenant"   # link to lease
    click_on "Record transaction"
    fill_in "description", with: "June rent"
    fill_in "amount", with: "1500"
    select "e-transfer", from: "method"
    fill_in "kind", with: "rent"
    fill_in "paid_on", with: ""
    click_on "Record"

    assert_text "Transaction recorded"
    assert_text "June rent"
    assert_text "$1500.00"
    assert_text "Pending"

    click_on "June rent"
    fill_in "paid_on", with: "2026-06-15"
    click_on "Mark paid"
    assert_text "Marked paid"
    assert_text "Paid"
    assert_text "2026-06-15"
    assert_no_text "Pending"

    # Edit the transaction
    click_on "Edit"
    fill_in "amount", with: "1450"
    click_on "Save"
    assert_text "Transaction updated"
    assert_text "$1450.00"
  end

  test "create and revoke an API token" do
    sign_in_as("5550000010")
    mint_api_token(label: "iOS app")
    assert_text "Token created"
    assert_text "iOS app"
    assert_text "Copy it now"

    click_on "Revoke"
    assert_text "Token revoked"
    assert_text "Revoked"
  end

  test "archive and unarchive a lease" do
    sign_in_as("5559700000")
    create_property(name: "Archive Sample", address: "12 Archive Way")
    create_applicant(name: "Archy McLease", mobile: "5559701111", summary: "Test.", property_address: "12 Archive Way")
    create_lease_for("Archy McLease", rent: "1500", start_date: "2026-01-01")

    click_on "Archy McLease"   # tenant link → lease show
    click_on "Archive"
    assert_text "Lease archived"
    assert_text "Archived"

    click_on "Leases"
    assert_no_text "Archy McLease"

    click_on "Archived"
    assert_text "Archy McLease"

    click_on "Archy McLease"
    click_on "Unarchive"
    assert_text "Lease unarchived"
    click_on "Leases"
    assert_text "Archy McLease"
  end

  test "edit a lease" do
    sign_in_as("5559001000")
    create_property(name: "Date Tester", address: "9 Date Lane")
    create_applicant(name: "Pat Renter", mobile: "5559002000", summary: "Test.", property_address: "9 Date Lane")
    create_lease_for("Pat Renter", rent: "1500", start_date: "2026-02-01")

    click_on "Pat Renter"   # tenant name links to lease show
    click_on "Edit lease"
    fill_in "end_date", with: "2027-06-30"
    click_on "Save"

    assert_text "Lease updated"
    assert_text "2027-06-30"
  end

  test "rent roll lists active leases; one-click 'Record rent' creates a paid tx" do
    sign_in_as("5557001000")
    create_property(name: "Roll Sample", address: "10 Roll Lane")
    create_applicant(name: "Roll Tenant", mobile: "5557002000", summary: "Roll.", property_address: "10 Roll Lane")
    create_lease_for("Roll Tenant", rent: "2000", start_date: "2026-01-01")

    click_on "Leases"
    assert_text "Roll Tenant"
    assert_text "$2000.00"
    assert_text "monthly"

    click_on "Record rent"
    assert_text "Rent recorded"
    assert_text "Roll Tenant"   # back on leases (rent roll) page
  end

  test "tenants page lists applicants with at least one lease" do
    sign_in_as("5559900000")
    create_property(name: "Coastal Cottage", address: "1 Sea Lane")

    create_applicant(name: "Walk-in Without Lease", mobile: "5559911111", summary: "Just looking.")
    create_applicant(name: "Tenant With Lease", mobile: "5559922222", summary: "Will get a lease.", property_address: "1 Sea Lane")
    create_lease_for("Tenant With Lease", rent: "1200", start_date: "2026-01-01")

    click_on "Tenants"
    assert_text "Tenant With Lease"
    assert_no_text "Walk-in Without Lease"

    click_on "Tenant With Lease"
    assert_text "1 Sea Lane"
    assert_text "View application"
  end

  test "create and edit a tax" do
    sign_in_as("5552220011")
    click_on "Taxes"
    assert_text "No taxes defined"

    click_on "New tax"
    fill_in "name", with: "GST"
    fill_in "rate", with: "5"
    click_on "Create"
    assert_text "GST"
    assert_text "5%"

    click_on "Edit"
    fill_in "name", with: "GST/HST"
    fill_in "rate", with: "13"
    click_on "Save"
    assert_text "GST/HST"
    assert_text "13%"
  end

  test "lease can apply taxes; rent roll shows total including tax" do
    sign_in_as("5552220022")
    create_property(name: "Tax Suite", address: "21 Tax Way")
    create_applicant(name: "Taxed Tenant", mobile: "5552220033", summary: "Pays tax.", property_address: "21 Tax Way")

    click_on "Taxes"
    click_on "New tax"
    fill_in "name", with: "GST"
    fill_in "rate", with: "5"
    click_on "Create"

    click_on "Applicants"
    click_on "Taxed Tenant"
    click_on "Create lease"
    fill_in "rent", with: "1000"
    fill_in "start_date", with: "2026-01-01"
    check "GST (5%)"
    click_on "Create lease"
    assert_text "Lease created"

    click_on "Taxed Tenant"
    assert_text "GST (5%)"
    assert_text "Total:"
    assert_text "$1050.00"

    click_on "Leases"
    assert_text "$1050.00"

    click_on "Record rent"
    assert_text "Rent recorded"
    click_on "Taxed Tenant"   # back into lease via tx list
    assert_text "$1050.00"
  end

  test "tenants page hides inactive tenants by default; show-inactive reveals them" do
    sign_in_as("5559933000")
    create_property(name: "Active House", address: "100 Active Way")
    create_property(name: "Past House", address: "200 Past Way")

    create_applicant(name: "Active Annie", mobile: "5559933001", summary: "Currently renting.", property_address: "100 Active Way")
    create_lease_for("Active Annie", rent: "1000", start_date: "2026-01-01")

    create_applicant(name: "Former Frank", mobile: "5559933002", summary: "Used to rent.", property_address: "200 Past Way")
    create_lease_for("Former Frank", rent: "1000", start_date: "2024-01-01", end_date: "2024-12-31")

    click_on "Tenants"
    assert_text "Active Annie"
    assert_no_text "Former Frank"

    click_on "Show inactive"
    assert_text "Active Annie"
    assert_text "Former Frank"
    assert_text "Inactive"

    click_on "Hide inactive"
    assert_no_text "Former Frank"
  end

  test "admin can upload photos for a property; public sees them" do
    sign_in_as("5550000060")
    create_property(name: "Photo House", address: "1 Photo Way", publish: true)
    click_on "Edit"
    attach_file "photos", Rails.root.join("test/fixtures/files/sample.jpg").to_s
    click_on "Upload"
    assert_text "Photos uploaded"

    click_on "Log out"
    visit "/properties/photo-house"
    assert_selector "img[alt='Photo House photo 1']"
  end

  test "admin can reorder and remove property photos" do
    sign_in_as("5550000061")
    create_property(name: "Reorder House", address: "2 Reorder Way")
    click_on "Edit"
    attach_file "photos", Rails.root.join("test/fixtures/files/sample.jpg").to_s
    click_on "Upload"
    attach_file "photos", Rails.root.join("test/fixtures/files/sample.jpg").to_s
    click_on "Upload"
    assert_selector ".photo-thumbs li", count: 2

    within all(".photo-thumbs li").first do
      click_on "×"
    end
    assert_text "Photo removed"
    assert_selector ".photo-thumbs li", count: 1
  end

  test "admin can change brand name and theme colors via settings" do
    sign_in_as("5550000050")
    click_on "Settings"
    fill_in "brand_name", with: "Acme Rentals"
    fill_in "primary_color", with: "#ff6600"
    fill_in "background_color", with: "#111111"
    fill_in "text_color", with: "#eeeeee"
    click_on "Save"

    assert_text "Settings saved"
    assert_field "brand_name", with: "Acme Rentals"
    visit "/dashboard"
    assert_text "Acme Rentals"
  end

  test "non-admin cannot access admin pages" do
    sign_in_as("5550000001")  # first login → admin
    click_on "Log out"

    sign_in_as("5550000002")  # second login → non-admin
    assert_no_link "Properties"

    visit "/properties"
    assert_text "Admin access required"

    visit "/properties/new"
    assert_text "Admin access required"
  end
end
