class Lease
  Result = Data.define(:lease)

  def self.call(lease_id:)
    lease = Leases.call(include_archived: true).leases.find { |l| l.id == lease_id }
    Result.new(lease: lease)
  end
end
