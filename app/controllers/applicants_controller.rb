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
    raise NotFoundError, "Applicant not found." unless @application
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
      format.json { head :created }
    end
  end

  def apply
    @property = PropertyBySlug.call(slug: params[:slug]).property
    raise NotFoundError, "Property not found." unless @property && @property.published
    @form = blank_form
  end

  def submit
    SubmitApplication.call(
      slug: params[:slug],
      name: params[:name],
      mobile: params[:mobile],
      summary: params[:summary]
    )
    respond_to do |format|
      format.html { redirect_to property_public_path(params[:slug]), notice: "Application received. We'll be in touch." }
      format.json { render json: { ok: true }, status: :created }
    end
  end

  private

  def blank_form
    Data.define(:name, :mobile, :summary).new(name: "", mobile: "", summary: "")
  end
end
