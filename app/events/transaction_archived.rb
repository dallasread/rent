class TransactionArchived < RailsEventStore::Event
  # data: { tx_id:, mobile:, archived_at: }
end
