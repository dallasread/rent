class LeasesController < ApplicationController
  def index
    @result = Leases.call
    respond_to do |format|
      format.html
      format.json { render json: { leases: @result.leases.map(&:to_h) } }
    end
  end

  def show
    @lease = Lease.call(lease_id: params[:id]).lease
    if @lease.nil?
      respond_to do |format|
        format.html { redirect_to(leases_path, alert: "Lease not found.") }
        format.json { render json: { error: "Lease not found." }, status: :not_found }
      end
      return
    end
    respond_to do |format|
      format.html
      format.json { render json: { lease: @lease.to_h } }
    end
  end

  def new
    @applicant = Applicant.call(applicant_id: params[:applicant_id]).application
    redirect_to(applicants_path, alert: "Applicant not found.") and return unless @applicant
    @properties = Properties.call.properties
    @form = Data.define(:start_date, :end_date, :property_id).new(
      start_date: Date.current.iso8601,
      end_date: nil,
      property_id: @applicant.property_id
    )
  end

  def create
    CreateLease.call(
      actor: current_user.mobile,
      applicant_id: params[:applicant_id],
      property_id: params[:property_id],
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    respond_to do |format|
      format.html { redirect_to leases_path, notice: "Lease created." }
      format.json {
        latest = Leases.call.leases.find { |l| l.applicant_id == params[:applicant_id] && l.property_id == params[:property_id] }
        render json: { lease: latest&.to_h }, status: :created
      }
    end
  end
end
