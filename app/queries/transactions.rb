class Transactions
  TransactionView = Data.define(
    :id, :lease_id, :kind, :amount_cents, :description, :method, :paid_at, :recorded_at
  ) do
    def paid?
      !paid_at.nil?
    end
  end

  Result = Data.define(:transactions)

  def self.call(lease_id: nil)
    events = Rails.configuration.event_store.read
      .stream("Transactions")
      .of_type([ TransactionRecorded ])
      .to_a

    updates = Rails.configuration.event_store.read
      .of_type([ TransactionUpdated ])
      .to_a
      .group_by { |e| e.data[:tx_id] }

    paid_overrides = Rails.configuration.event_store.read
      .of_type([ TransactionMarkedPaid ])
      .to_a
      .each_with_object({}) { |e, h| h[e.data[:tx_id]] = e.data[:paid_at] }

    txs = events.map do |e|
      tx_id = e.data[:tx_id]
      latest_update = updates[tx_id]&.last
      data = latest_update ? latest_update.data : e.data
      paid_at = paid_overrides[tx_id] || data[:paid_at]

      TransactionView.new(
        id: tx_id,
        lease_id: e.data[:lease_id],
        kind: data[:kind].to_s.presence || "rent",
        amount_cents: data[:amount_cents].to_i,
        description: data[:description].to_s,
        method: data[:method].to_s,
        paid_at: paid_at,
        recorded_at: e.data[:recorded_at]
      )
    end

    txs = txs.select { |t| t.lease_id == lease_id } if lease_id
    Result.new(transactions: txs.sort_by { |t| t.recorded_at || Time.current }.reverse)
  end
end
