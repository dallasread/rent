class LeasesController < ApplicationController
  def index
    @scope = %w[current inactive archived].include?(params[:scope]) ? params[:scope].to_sym : :current
    @rent_roll = RentRoll.call(scope: @scope)
    respond_to do |format|
      format.html
      format.json {
        render json: {
          as_of: @rent_roll.as_of,
          entries: @rent_roll.entries.map { |e|
            {
              lease_id: e.lease.id,
              property_id: e.lease.property_id,
              applicant_id: e.lease.applicant_id,
              rent_cents: e.lease.rent_cents,
              total_cents: e.total_cents,
              frequency: e.lease.frequency,
              paid_through: e.paid_through,
              next_due_on: e.next_due_on,
              overdue: e.overdue?
            }
          }
        }
      }
    end
  end

  def show
    @lease = Lease.call(lease_id: params[:id]).lease
    respond_to do |format|
      format.html
      format.json { render json: { lease: @lease.to_h } }
    end
  end

  def new
    @applicant = Applicant.call(applicant_id: params[:applicant_id]).application
    @properties = Properties.call.properties
    @taxes = Taxes.call.taxes
    @form = Data.define(:start_date, :end_date, :property_id, :rent, :frequency, :tax_ids).new(
      start_date: Date.current.iso8601,
      end_date: nil,
      property_id: @applicant.property_id,
      rent: nil,
      frequency: "monthly",
      tax_ids: []
    )
  end

  def create
    CreateLease.call(
      actor: current_user.id,
      applicant_id: params[:applicant_id],
      property_id: params[:property_id],
      start_date: params[:start_date],
      end_date: params[:end_date],
      rent: params[:rent],
      frequency: params[:frequency],
      tax_ids: Array(params[:tax_ids])
    )
    respond_to do |format|
      format.html { redirect_to leases_path, notice: "Lease created." }
      format.json { head :created }
    end
  end

  def edit
    @lease = Lease.call(lease_id: params[:id]).lease
    @taxes = Taxes.call.taxes
  end

  def update
    UpdateLease.call(
      lease_id: params[:id],
      actor: current_user.id,
      start_date: params[:start_date],
      end_date: params[:end_date],
      rent: params[:rent],
      frequency: params[:frequency],
      tax_ids: Array(params[:tax_ids])
    )
    respond_to do |format|
      format.html { redirect_to lease_path(params[:id]), notice: "Lease updated." }
      format.json { head :no_content }
    end
  end

  def archive
    ArchiveLease.call(lease_id: params[:id], actor: current_user.id)
    respond_to do |format|
      format.html { redirect_to lease_path(params[:id]), notice: "Lease archived." }
      format.json { head :no_content }
    end
  end

  def unarchive
    UnarchiveLease.call(lease_id: params[:id], actor: current_user.id)
    respond_to do |format|
      format.html { redirect_to lease_path(params[:id]), notice: "Lease unarchived." }
      format.json { head :no_content }
    end
  end
end
