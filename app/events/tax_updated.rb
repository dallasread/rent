class TaxUpdated < RailsEventStore::Event
  # data: { tax_id:, name:, rate_bp:, mobile:, updated_at: }
end
