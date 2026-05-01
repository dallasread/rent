class TaxesController < ApplicationController
  def index
    @result = Taxes.call
  end

  def new
    @form = Data.define(:name, :rate).new(name: "", rate: nil)
  end

  def create
    AddTax.call(actor: current_user.mobile, name: params[:name], rate: params[:rate])
    redirect_to taxes_path, notice: "Tax added."
  end

  def edit
    @tax = Tax.call(tax_id: params[:id]).tax
  end

  def update
    UpdateTax.call(
      actor: current_user.mobile,
      tax_id: params[:id],
      name: params[:name],
      rate: params[:rate]
    )
    redirect_to taxes_path, notice: "Tax updated."
  end
end
