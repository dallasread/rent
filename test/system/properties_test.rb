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
