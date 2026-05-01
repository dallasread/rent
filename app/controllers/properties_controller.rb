class PropertiesController < ApplicationController
  def index
    @result = Properties.call
  end

  def new
    @form = blank_form
  end

  def create
    AddProperty.call(
      actor: current_user.mobile,
      name: params[:name],
      address: params[:address],
      beds: params[:beds],
      baths: params[:baths],
      description: params[:description]
    )
    redirect_to properties_path, notice: "Property added."
  end

  def show
    @property = PropertyBySlug.call(slug: params[:slug]).property
    visible = @property && (@property.published || authenticated?)
    unless visible
      redirect_to(authenticated? ? properties_path : login_path, alert: "Property not found.") and return
    end
  end

  def edit
    @property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless @property
  end

  def update
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    UpdateProperty.call(
      property_id: property.id,
      actor: current_user.mobile,
      name: params[:name],
      address: params[:address],
      slug: params[:permalink],
      beds: params[:beds],
      baths: params[:baths],
      description: params[:description]
    )
    redirect_to properties_path, notice: "Property updated."
  end

  def destroy
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    RemoveProperty.call(property_id: property.id, actor: current_user.mobile)
    redirect_to properties_path, notice: "Property removed."
  end

  def duplicate
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    DuplicateProperty.call(property_id: property.id, actor: current_user.mobile)
    new_slug = LatestPropertyAdded.call(mobile: current_user.mobile).slug
    redirect_to edit_property_path(new_slug), notice: "Property duplicated. Adjust as needed."
  end

  def publish
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    PublishProperty.call(property_id: property.id, actor: current_user.mobile)
    redirect_to properties_path, notice: "Property published."
  end

  def unpublish
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    UnpublishProperty.call(property_id: property.id, actor: current_user.mobile)
    redirect_to properties_path, notice: "Property unpublished."
  end

  private

  def blank_form
    Data.define(:slug, :name, :address, :beds, :baths, :description).new(
      slug: nil, name: "", address: "", beds: 1, baths: 1, description: ""
    )
  end
end
