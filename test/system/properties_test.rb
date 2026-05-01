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

  test "show page is public; edit link only when logged in" do
    sign_in("5551112222")
    visit "/properties/new"
    fill_in "name", with: "Public Listing"
    fill_in "beds", with: 2
    fill_in "baths", with: 1
    fill_in "description", with: "Open to all."
    click_on "Create"
    click_on "Log out"
    assert_text "Log in"

    visit "/properties/public-listing"
    assert_text "Public Listing"
    assert_text "Open to all."
    assert_no_link "Edit this property"

    sign_in("5551112222")
    visit "/properties/public-listing"
    assert_link "Edit this property"
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
