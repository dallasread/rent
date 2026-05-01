class ApplicantsController < ApplicationController
  def index
    @show_archived = params[:archived] == "1"
    @result = Applications.call(include_archived: @show_archived)
    respond_to do |format|
      format.html
      format.json { render json: { applicants: @result.applications.map(&:to_h) } }
    end
  end

  def show
    @application = Applicant.call(applicant_id: params[:id]).application
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
    raise NotFoundError, "Property not found." unless @property.published
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

  def archive
    ArchiveApplicant.call(application_id: params[:id], actor: current_user.mobile)
    redirect_to applicant_path(params[:id]), notice: "Applicant archived."
  end

  def unarchive
    UnarchiveApplicant.call(application_id: params[:id], actor: current_user.mobile)
    redirect_to applicant_path(params[:id]), notice: "Applicant unarchived."
  end

  private

  def blank_form
    Data.define(:name, :mobile, :summary).new(name: "", mobile: "", summary: "")
  end
end
