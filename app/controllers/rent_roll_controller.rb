class RentRollController < ApplicationController
  def show
    @result = RentRoll.call
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
    redirect_to rent_roll_path, notice: "Rent recorded."
  end
end
