class PropertiesController < ApplicationController
  def index
    @result = Properties.call
    respond_to do |format|
      format.html
      format.json { render json: { properties: @result.properties.map(&:to_h) } }
    end
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
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property added." }
      format.json {
        slug = LatestPropertyAdded.call(mobile: current_user.mobile).slug
        prop = PropertyBySlug.call(slug: slug).property
        render json: { property: prop.to_h }, status: :created
      }
    end
  end

  def show
    @property = PropertyBySlug.call(slug: params[:slug]).property
    raise NotFoundError, "Property not found." unless @property.published || authenticated?
    respond_to do |format|
      format.html
      format.json { render json: { property: @property.to_h } }
    end
  end

  def edit
    @property = Property.call(property_id: params[:id]).property
  end

  def update
    UpdateProperty.call(
      property_id: params[:id],
      actor: current_user.mobile,
      name: params[:name],
      address: params[:address],
      permalink: params[:permalink],
      beds: params[:beds],
      baths: params[:baths],
      description: params[:description]
    )
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property updated." }
      format.json { head :no_content }
    end
  end

  def destroy
    RemoveProperty.call(property_id: params[:id], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property removed." }
      format.json { head :no_content }
    end
  end

  def duplicate
    DuplicateProperty.call(property_id: params[:id], actor: current_user.mobile)
    new_id = LatestPropertyAdded.call(mobile: current_user.mobile).property_id
    respond_to do |format|
      format.html { redirect_to edit_property_path(new_id), notice: "Property duplicated. Adjust as needed." }
      format.json { head :created }
    end
  end

  def publish
    PublishProperty.call(property_id: params[:id], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property published." }
      format.json { head :no_content }
    end
  end

  def unpublish
    UnpublishProperty.call(property_id: params[:id], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property unpublished." }
      format.json { head :no_content }
    end
  end

  def attach_photo
    Array(params[:photos]).each do |file|
      next if file.blank?
      AttachPhoto.call(actor: current_user.mobile, property_id: params[:id], file: file)
    end
    respond_to do |format|
      format.html { redirect_to edit_property_path(params[:id]), notice: "Photos uploaded." }
      format.json { head :created }
    end
  end

  private

  def blank_form
    Data.define(:slug, :name, :address, :beds, :baths, :description).new(
      slug: nil, name: "", address: "", beds: 1, baths: 1, description: ""
    )
  end
end
