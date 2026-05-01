module Scenarios
  def sign_in_as(mobile = "5550000001")
    visit "/login"
    fill_in "mobile", with: mobile
    click_on "Send code"
    code = SmsClient::TestBackend.messages.last[:body][/\d{6}/]
    fill_in "code", with: code
    click_on "Log in"
    assert_text "Dashboard"
  end

  def create_property(name:, address:, beds: 1, baths: 1, description: nil, publish: false)
    visit "/properties/new"
    fill_in "name", with: name
    fill_in "address", with: address
    fill_in "beds", with: beds
    fill_in "baths", with: baths
    find("#description-input", visible: :all).set(description) if description
    click_on "Create"
    click_on "Publish" if publish
  end

  def create_applicant(name:, mobile:, summary:, property_address: nil)
    visit "/applicants/new"
    fill_in "name", with: name
    fill_in "mobile", with: mobile
    fill_in "summary", with: summary
    select property_address, from: "property_id" if property_address
    click_on "Add applicant"
  end

  def create_lease_for(applicant_name, rent:, start_date:, end_date: nil)
    click_on applicant_name
    click_on "Create lease"
    fill_in "rent", with: rent
    fill_in "start_date", with: start_date
    fill_in "end_date", with: end_date if end_date
    click_on "Create lease"
  end

  def public_apply_for(slug, name:, mobile:, summary:)
    visit "/properties/#{slug}"
    click_on "Apply for this property"
    fill_in "name", with: name
    fill_in "mobile", with: mobile
    fill_in "summary", with: summary
    click_on "Submit application"
  end

  def mint_api_token(label: "tester")
    click_on "API tokens"
    click_on "New token"
    fill_in "name", with: label
    click_on "Create"
    find("div.flash-notice code").text
  end
end
