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
    raise NotFoundError, "Lease not found." unless @lease
    respond_to do |format|
      format.html
      format.json { render json: { lease: @lease.to_h } }
    end
  end

  def new
    @applicant = Applicant.call(applicant_id: params[:applicant_id]).application
    raise NotFoundError, "Applicant not found." unless @applicant
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
      format.json { head :created }
    end
  end

  def edit
    @lease = Lease.call(lease_id: params[:id]).lease
    raise NotFoundError, "Lease not found." unless @lease
  end

  def update
    UpdateLease.call(
      lease_id: params[:id],
      actor: current_user.mobile,
      start_date: params[:start_date],
      end_date: params[:end_date]
    )
    respond_to do |format|
      format.html { redirect_to lease_path(params[:id]), notice: "Lease updated." }
      format.json { head :no_content }
    end
  end
end
