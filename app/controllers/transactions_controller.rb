class TransactionsController < ApplicationController
  def index
    @result = Transactions.call
  end

  def show
    @transaction = Transaction.call(tx_id: params[:id]).transaction
    redirect_to(transactions_path, alert: "Transaction not found.") and return unless @transaction
    @lease = Lease.call(lease_id: @transaction.lease_id).lease
  end

  def new
    @lease = Lease.call(lease_id: params[:lease_id]).lease
    redirect_to(leases_path, alert: "Lease not found.") and return unless @lease
    applicant = Applicant.call(applicant_id: @lease.applicant_id).application
    @form = Data.define(:amount, :paid_by, :description, :method, :note, :paid).new(
      amount: nil,
      paid_by: applicant&.name.to_s,
      description: "",
      method: "",
      note: "",
      paid: true
    )
  end

  def create
    RecordTransaction.call(
      actor: current_user.mobile,
      lease_id: params[:lease_id],
      amount: params[:amount],
      paid_by: params[:paid_by],
      description: params[:description],
      method: params[:method],
      note: params[:note],
      paid: params[:paid] == "1"
    )
    redirect_to lease_path(params[:lease_id]), notice: "Transaction recorded."
  end

  def mark_paid
    MarkTransactionPaid.call(actor: current_user.mobile, tx_id: params[:id])
    redirect_to transaction_path(params[:id]), notice: "Marked paid."
  end
end
