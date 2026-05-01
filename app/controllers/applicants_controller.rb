class ApplicantsController < ApplicationController
  def index
    @result = Applications.call
  end

  def show
    @application = Applications.call.applications.find { |a| a.id == params[:id] }
    redirect_to(applicants_path, alert: "Applicant not found.") and return unless @application
  end

  def new
    @form = blank_form
    @properties = Properties.call.properties
  end

  def create
    AddApplicant.call(
      actor: current_user.mobile,
      name: params[:name],
      mobile: params[:mobile],
      summary: params[:summary],
      property_id: params[:property_id]
    )
    redirect_to applicants_path, notice: "Applicant added."
  end

  def apply
    @property = PropertyBySlug.call(slug: params[:slug]).property
    unless @property && @property.published
      redirect_to login_path, alert: "Property not found." and return
    end
    @form = blank_form
  end

  def submit
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
