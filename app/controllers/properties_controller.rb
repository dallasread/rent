class PropertiesController < ApplicationController
  before_action :require_authentication

  def index
    @result = Properties.call
  end

  def new
    @form = blank_form
  end

  def create
    AddProperty.call(
      mobile: current_user.mobile,
      name: params[:name],
      beds: params[:beds],
      baths: params[:baths],
      description: params[:description]
    )
    redirect_to properties_path, notice: "Property added."
  end

  def edit
    @result = Property.call(property_id: params[:id])
    redirect_to properties_path, alert: "Property not found." and return unless @result.property
  end

  def update
    UpdateProperty.call(
      property_id: params[:id],
      mobile: current_user.mobile,
      name: params[:name],
      beds: params[:beds],
      baths: params[:baths],
      description: params[:description]
    )
    redirect_to properties_path, notice: "Property updated."
  end

  def destroy
    RemoveProperty.call(property_id: params[:id], mobile: current_user.mobile)
    redirect_to properties_path, notice: "Property removed."
  end

  def duplicate
    DuplicateProperty.call(property_id: params[:id], mobile: current_user.mobile)
    new_id = LatestPropertyAdded.call(mobile: current_user.mobile).property_id
    redirect_to edit_property_path(new_id), notice: "Property duplicated. Adjust as needed."
  end

  private

  def blank_form
    Data.define(:id, :name, :beds, :baths, :description).new(
      id: nil, name: "", beds: 1, baths: 1, description: ""
    )
  end
end
