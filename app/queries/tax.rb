class Tax
  Result = Data.define(:tax)

  def self.call(tax_id:)
    tax = Taxes.call.taxes.find { |t| t.id == tax_id }
    raise NotFoundError, "Tax not found." unless tax
    Result.new(tax: tax)
  end
end
