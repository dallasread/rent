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
    @form = Data.define(:amount, :description, :method, :paid_on).new(
      amount: nil,
      description: "",
      method: RecordTransaction::METHODS.first,
      paid_on: Date.current.iso8601
    )
  end

  def create
    RecordTransaction.call(
      actor: current_user.mobile,
      lease_id: params[:lease_id],
      amount: params[:amount],
      description: params[:description],
      method: params[:method],
      paid_on: params[:paid_on]
    )
    redirect_to lease_path(params[:lease_id]), notice: "Transaction recorded."
  end

  def mark_paid
    MarkTransactionPaid.call(
      actor: current_user.mobile,
      tx_id: params[:id],
      paid_on: params[:paid_on]
    )
    redirect_to transaction_path(params[:id]), notice: "Marked paid."
  end
end
