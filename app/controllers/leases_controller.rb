class LeasesController < ApplicationController
  def index
    @result = Leases.call
  end

  def show
    @lease = Lease.call(lease_id: params[:id]).lease
    redirect_to(leases_path, alert: "Lease not found.") and return unless @lease
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
    redirect_to leases_path, notice: "Lease created."
  end
end
