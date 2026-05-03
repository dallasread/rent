class TaxUpdated < RailsEventStore::Event
  # data: { tax_id:, name:, rate_bp:, actor_id:, updated_at: }
end
