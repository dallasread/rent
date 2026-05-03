class TransactionsController < ApplicationController
  def index
    @show_archived = params[:archived] == "1"
    @result = Transactions.call(include_archived: @show_archived)
    respond_to do |format|
      format.html
      format.json { render json: { transactions: @result.transactions.map(&:to_h) } }
    end
  end

  def show
    @transaction = Transaction.call(tx_id: params[:id]).transaction
    @lease = Lease.call(lease_id: @transaction.lease_id).lease
    respond_to do |format|
      format.html
      format.json { render json: { transaction: @transaction.to_h } }
    end
  end

  def new
    @lease = Lease.call(lease_id: params[:lease_id]).lease
    @form = Data.define(:amount, :description, :method, :kind, :paid_on).new(
      amount: params[:amount].presence || (@lease.rent_cents.to_i.positive? ? format("%.2f", @lease.rent_cents / 100.0) : nil),
      description: params[:description].presence || "",
      method: params[:method].presence || RecordTransaction::METHODS.first,
      kind: params[:kind].presence || "rent",
      paid_on: params[:paid_on].presence || Date.current.iso8601
    )
  end

  def create
    RecordTransaction.call(
      actor: current_user.id,
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

  def edit
    @transaction = Transaction.call(tx_id: params[:id]).transaction
    @lease = Lease.call(lease_id: @transaction.lease_id).lease
  end

  def update
    UpdateTransaction.call(
      actor: current_user.id,
      tx_id: params[:id],
      amount: params[:amount],
      description: params[:description],
      method: params[:method],
      kind: params[:kind],
      paid_on: params[:paid_on]
    )
    respond_to do |format|
      format.html { redirect_to transaction_path(params[:id]), notice: "Transaction updated." }
      format.json { head :no_content }
    end
  end

  def mark_paid
    MarkTransactionPaid.call(
      actor: current_user.id,
      tx_id: params[:id],
      paid_on: params[:paid_on]
    )
    respond_to do |format|
      format.html { redirect_to transaction_path(params[:id]), notice: "Marked paid." }
      format.json { head :no_content }
    end
  end

  def archive
    ArchiveTransaction.call(tx_id: params[:id], actor: current_user.id)
    redirect_to transaction_path(params[:id]), notice: "Transaction archived."
  end

  def unarchive
    UnarchiveTransaction.call(tx_id: params[:id], actor: current_user.id)
    redirect_to transaction_path(params[:id]), notice: "Transaction unarchived."
  end
end
