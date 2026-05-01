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

    paid_overrides = paid_overrides_lookup

    txs = events.map do |e|
      paid_at = paid_overrides[e.data[:tx_id]] || e.data[:paid_at]
      TransactionView.new(
        id: e.data[:tx_id],
        lease_id: e.data[:lease_id],
        kind: e.data[:kind].to_s.presence || "rent",
        amount_cents: e.data[:amount_cents].to_i,
        description: e.data[:description].to_s,
        method: e.data[:method].to_s,
        paid_at: paid_at,
        recorded_at: e.data[:recorded_at]
      )
    end

    txs = txs.select { |t| t.lease_id == lease_id } if lease_id
    Result.new(transactions: txs.sort_by { |t| t.recorded_at || Time.current }.reverse)
  end

  def self.paid_overrides_lookup
    Rails.configuration.event_store.read
      .of_type([ TransactionMarkedPaid ])
      .to_a
      .each_with_object({}) { |e, h| h[e.data[:tx_id]] = e.data[:paid_at] }
  end
end
