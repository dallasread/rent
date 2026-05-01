class ApplicantsController < ApplicationController
  def index
    @result = Applications.call
  end

  def new
    @property = PropertyBySlug.call(slug: params[:slug]).property
    unless @property && @property.published
      redirect_to login_path, alert: "Property not found." and return
    end
    @form = blank_form
  end

  def create
    property = PropertyBySlug.call(slug: params[:slug]).property
    redirect_to(login_path, alert: "Property not found.") and return unless property

    SubmitApplication.call(
      property_id: property.id,
      name: params[:name],
      mobile: params[:mobile],
      summary: params[:summary]
    )
    redirect_to property_path(property.slug), notice: "Application received. We'll be in touch."
  end

  private

  def blank_form
    Data.define(:name, :mobile, :summary).new(name: "", mobile: "", summary: "")
  end
end
