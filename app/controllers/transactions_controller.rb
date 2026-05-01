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
    if @transaction.nil?
      respond_to do |format|
        format.html { redirect_to(transactions_path, alert: "Transaction not found.") }
        format.json { render json: { error: "Transaction not found." }, status: :not_found }
      end
      return
    end
    @lease = Lease.call(lease_id: @transaction.lease_id).lease
    respond_to do |format|
      format.html
      format.json { render json: { transaction: @transaction.to_h } }
    end
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
    respond_to do |format|
      format.html { redirect_to lease_path(params[:lease_id]), notice: "Transaction recorded." }
      format.json {
        latest = Transactions.call(lease_id: params[:lease_id]).transactions.first
        render json: { transaction: latest&.to_h }, status: :created
      }
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
      format.json {
        tx = Transaction.call(tx_id: params[:id]).transaction
        render json: { transaction: tx.to_h }
      }
    end
  end
end
