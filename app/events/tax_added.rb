class TaxAdded < RailsEventStore::Event
  # data: { tax_id:, name:, rate_bp:, actor_id:, added_at: }
end
