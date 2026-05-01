class TaxAdded < RailsEventStore::Event
  # data: { tax_id:, name:, rate_bp:, mobile:, added_at: }
end
