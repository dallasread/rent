class ApplicantsController < ApplicationController
  def index
    @result = Applications.call
    respond_to do |format|
      format.html
      format.json { render json: { applicants: @result.applications.map(&:to_h) } }
    end
  end

  def show
    @application = Applicant.call(applicant_id: params[:id]).application
    if @application.nil?
      respond_to do |format|
        format.html { redirect_to(applicants_path, alert: "Applicant not found.") }
        format.json { render json: { error: "Applicant not found." }, status: :not_found }
      end
      return
    end
    respond_to do |format|
      format.html
      format.json { render json: { applicant: @application.to_h } }
    end
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
    respond_to do |format|
      format.html { redirect_to applicants_path, notice: "Applicant added." }
      format.json {
        latest = Applications.call.applications.first { |a| a.name == params[:name].to_s.strip && a.mobile == params[:mobile].to_s.strip }
        render json: { applicant: latest&.to_h }, status: :created
      }
    end
  end

  def apply
    @property = PropertyBySlug.call(slug: params[:slug]).property
    unless @property && @property.published
      respond_to do |format|
        format.html { redirect_to login_path, alert: "Property not found." }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end
    @form = blank_form
  end

  def submit
    property = PropertyBySlug.call(slug: params[:slug]).property
    if property.nil?
      respond_to do |format|
        format.html { redirect_to(login_path, alert: "Property not found.") }
        format.json { render json: { error: "Property not found." }, status: :not_found }
      end
      return
    end

    SubmitApplication.call(
      property_id: property.id,
      name: params[:name],
      mobile: params[:mobile],
      summary: params[:summary]
    )
    respond_to do |format|
      format.html { redirect_to property_path(property.slug), notice: "Application received. We'll be in touch." }
      format.json { render json: { ok: true }, status: :created }
    end
  end

  private

  def blank_form
    Data.define(:name, :mobile, :summary).new(name: "", mobile: "", summary: "")
  end
end
