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
    visible = @property && (@property.published || authenticated?)
    raise NotFoundError, "Property not found." unless visible
    respond_to do |format|
      format.html
      format.json { render json: { property: @property.to_h } }
    end
  end

  def edit
    @property = PropertyBySlug.call(slug: params[:slug]).property
    raise NotFoundError, "Property not found." unless @property
  end

  def update
    UpdateProperty.call(
      slug: params[:slug],
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
    RemoveProperty.call(slug: params[:slug], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property removed." }
      format.json { head :no_content }
    end
  end

  def duplicate
    DuplicateProperty.call(slug: params[:slug], actor: current_user.mobile)
    new_slug = LatestPropertyAdded.call(mobile: current_user.mobile).slug
    respond_to do |format|
      format.html { redirect_to edit_property_path(new_slug), notice: "Property duplicated. Adjust as needed." }
      format.json {
        prop = PropertyBySlug.call(slug: new_slug).property
        render json: { property: prop.to_h }, status: :created
      }
    end
  end

  def publish
    PublishProperty.call(slug: params[:slug], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property published." }
      format.json { head :no_content }
    end
  end

  def unpublish
    UnpublishProperty.call(slug: params[:slug], actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property unpublished." }
      format.json { head :no_content }
    end
  end

  private

  def blank_form
    Data.define(:slug, :name, :address, :beds, :baths, :description).new(
      slug: nil, name: "", address: "", beds: 1, baths: 1, description: ""
    )
  end
end
