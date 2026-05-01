class TransactionsController < ApplicationController
  def index
    @result = Transactions.call
    respond_to do |format|
      format.html
      format.json { render json: { transactions: @result.transactions.map(&:to_h) } }
    end
  end

  def show
    @transaction = Transaction.call(tx_id: params[:id]).transaction
    raise NotFoundError, "Transaction not found." unless @transaction
    @lease = Lease.call(lease_id: @transaction.lease_id).lease
    respond_to do |format|
      format.html
      format.json { render json: { transaction: @transaction.to_h } }
    end
  end

  def new
    @lease = Lease.call(lease_id: params[:lease_id]).lease
    raise NotFoundError, "Lease not found." unless @lease
    @form = Data.define(:amount, :description, :method, :kind, :paid_on).new(
      amount: nil,
      description: "",
      method: RecordTransaction::METHODS.first,
      kind: "rent",
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
      kind: params[:kind],
      paid_on: params[:paid_on]
    )
    respond_to do |format|
      format.html { redirect_to lease_path(params[:lease_id]), notice: "Transaction recorded." }
      format.json { head :created }
    end
  end

  def mark_paid
    MarkTransactionPaid.call(
      actor: current_user.mobile,
      tx_id: params[:id],
      paid_on: params[:paid_on]
    )
    respond_to do |format|
      format.html { redirect_to transaction_path(params[:id]), notice: "Marked paid." }
      format.json { head :no_content }
    end
  end
end
