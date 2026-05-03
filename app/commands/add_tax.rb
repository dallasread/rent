class AddTax
  class InvalidName < CommandError; end
  class InvalidRate < CommandError; end

  def self.call(actor:, name:, rate:)
    Authorization.check!(actor: actor, key: self.name)
    raise InvalidName, "Name is required." if name.to_s.strip.empty?

    bp = parse_rate_bp(rate)
    raise InvalidRate, "Rate must be a non-negative number." if bp.nil?

    tax_id = SecureRandom.uuid
    Rails.configuration.event_store.publish(
      TaxAdded.new(data: {
        tax_id: tax_id,
        name: name.to_s.strip,
        rate_bp: bp,
        actor_id: actor,
        added_at: Time.current
      }),
      stream_name: "Tax$#{tax_id}"
    ).then do
      Rails.configuration.event_store.link(
        [ Rails.configuration.event_store.read.stream("Tax$#{tax_id}").last.event_id ],
        stream_name: "Taxes"
      )
    end
    nil
  end

  def self.parse_rate_bp(input)
    return nil if input.to_s.strip.empty?
    f = Float(input.to_s)
    return nil if f < 0
    (f * 100).round
  rescue ArgumentError, TypeError
    nil
  end
end
