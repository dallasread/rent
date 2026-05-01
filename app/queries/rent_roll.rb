class RentRoll
  RollEntry = Data.define(:lease, :next_due_on, :overdue?, :paid_through, :total_cents)
  Result = Data.define(:as_of, :entries, :taxes_by_id)

  def self.call(as_of: Date.current)
    active = Leases.call.leases.select { |l| l.active_on?(as_of) }
    all_txs = Transactions.call.transactions
    taxes_by_id = Taxes.call.taxes.index_by(&:id)
    properties_by_id = Properties.call.properties.index_by(&:id)

    entries = active.map do |lease|
      paid_rent_count = all_txs.count do |t|
        t.lease_id == lease.id && t.kind == "rent" && t.paid?
      end
      next_due = next_due_on(lease, paid_rent_count)
      paid_through = paid_rent_count.zero? ? nil : next_due - 1
      RollEntry.new(
        lease: lease,
        next_due_on: next_due,
        overdue?: next_due && next_due <= as_of,
        paid_through: paid_through,
        total_cents: lease.total_cents(taxes_by_id)
      )
    end

    Result.new(
      as_of: as_of,
      entries: entries.sort_by { |e|
        p = properties_by_id[e.lease.property_id]
        (p&.address.presence || p&.name).to_s.downcase
      },
      taxes_by_id: taxes_by_id
    )
  end

  def self.next_due_on(lease, paid_count)
    add_periods(lease.start_date, paid_count, lease.frequency)
  end

  def self.add_periods(date, count, frequency)
    case frequency
    when "monthly"   then date >> count
    when "quarterly" then date >> (count * 3)
    when "weekly"    then date + (count * 7)
    when "biweekly"  then date + (count * 14)
    else                  date >> count
    end
  end
end
