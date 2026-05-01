class UpdateTax
  class NotFound < NotFoundError; end
  class InvalidName < CommandError; end
  class InvalidRate < CommandError; end

  def self.call(actor:, tax_id:, name:, rate:)
    Authorization.check!(actor: actor, key: self.name)
    Tax.call(tax_id: tax_id)  # raises if not found

    raise InvalidName, "Name is required." if name.to_s.strip.empty?
    bp = AddTax.parse_rate_bp(rate)
    raise InvalidRate, "Rate must be a non-negative number." if bp.nil?

    Rails.configuration.event_store.publish(
      TaxUpdated.new(data: {
        tax_id: tax_id,
        name: name.to_s.strip,
        rate_bp: bp,
        mobile: actor,
        updated_at: Time.current
      }),
      stream_name: "Tax$#{tax_id}"
    )
    nil
  end
end
