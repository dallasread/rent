class RentRollController < ApplicationController
  def show
    @result = RentRoll.call
    respond_to do |format|
      format.html
      format.json {
        render json: {
          as_of: @result.as_of,
          entries: @result.entries.map { |e|
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

  def record
    lease = Lease.call(lease_id: params[:lease_id]).lease
    paid_count = Transactions.call(lease_id: lease.id).transactions.count { |t| t.kind == "rent" && t.paid? }
    next_due = RentRoll.next_due_on(lease, paid_count)
    taxes_by_id = Taxes.call.taxes.index_by(&:id)
    total_cents = lease.total_cents(taxes_by_id)

    RecordTransaction.call(
      actor: current_user.mobile,
      lease_id: lease.id,
      amount: format("%.2f", total_cents / 100.0),
      description: "Rent for #{next_due&.strftime('%B %Y')}",
      method: RecordTransaction::METHODS.first,
      kind: "rent",
      paid_on: Date.current.iso8601
    )
    respond_to do |format|
      format.html { redirect_to rent_roll_path, notice: "Rent recorded." }
      format.json { head :created }
    end
  end
end
