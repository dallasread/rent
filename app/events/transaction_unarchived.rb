class TransactionUnarchived < RailsEventStore::Event
  # data: { tx_id:, mobile:, unarchived_at: }
end
