class TaxesController < ApplicationController
  def index
    @result = Taxes.call
    respond_to do |format|
      format.html
      format.json { render json: { taxes: @result.taxes.map(&:to_h) } }
    end
  end

  def show
    @tax = Tax.call(tax_id: params[:id]).tax
    respond_to do |format|
      format.html { redirect_to edit_tax_path(@tax.id) }
      format.json { render json: { tax: @tax.to_h } }
    end
  end

  def new
    @form = Data.define(:name, :rate).new(name: "", rate: nil)
  end

  def create
    AddTax.call(actor: current_user.id, name: params[:name], rate: params[:rate])
    respond_to do |format|
      format.html { redirect_to taxes_path, notice: "Tax added." }
      format.json { head :created }
    end
  end

  def edit
    @tax = Tax.call(tax_id: params[:id]).tax
  end

  def update
    UpdateTax.call(
      actor: current_user.id,
      tax_id: params[:id],
      name: params[:name],
      rate: params[:rate]
    )
    respond_to do |format|
      format.html { redirect_to taxes_path, notice: "Tax updated." }
      format.json { head :no_content }
    end
  end
end
