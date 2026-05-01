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
    unless visible
      respond_to do |format|
        format.html { redirect_to(authenticated? ? properties_path : login_path, alert: "Property not found.") }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end
    respond_to do |format|
      format.html
      format.json { render json: { property: @property.to_h } }
    end
  end

  def edit
    @property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless @property
  end

  def update
    property = PropertyBySlug.call(slug: params[:slug]).property
    if property.nil?
      respond_to do |format|
        format.html { redirect_to(properties_path, alert: "Property not found.") }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end

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
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property updated." }
      format.json {
        updated = Property.call(property_id: property.id).property
        render json: { property: updated.to_h }
      }
    end
  end

  def destroy
    property = PropertyBySlug.call(slug: params[:slug]).property
    if property.nil?
      respond_to do |format|
        format.html { redirect_to(properties_path, alert: "Property not found.") }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end

    RemoveProperty.call(property_id: property.id, actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: "Property removed." }
      format.json { head :no_content }
    end
  end

  def duplicate
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to properties_path, alert: "Property not found." and return unless property

    DuplicateProperty.call(property_id: property.id, actor: current_user.mobile)
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
    toggle_published(:publish, "Property published.")
  end

  def unpublish
    toggle_published(:unpublish, "Property unpublished.")
  end

  private

  def toggle_published(action, notice)
    property = PropertyBySlug.call(slug: params[:slug]).property
    if property.nil?
      respond_to do |format|
        format.html { redirect_to(properties_path, alert: "Property not found.") }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end

    cmd = action == :publish ? PublishProperty : UnpublishProperty
    cmd.call(property_id: property.id, actor: current_user.mobile)
    respond_to do |format|
      format.html { redirect_to properties_path, notice: notice }
      format.json {
        updated = Property.call(property_id: property.id).property
        render json: { property: updated.to_h }
      }
    end
  end

  def blank_form
    Data.define(:slug, :name, :address, :beds, :baths, :description).new(
      slug: nil, name: "", address: "", beds: 1, baths: 1, description: ""
    )
  end
end
