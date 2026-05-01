class Lease
  Result = Data.define(:lease)

  def self.call(lease_id:)
    lease = Leases.call(include_archived: true).leases.find { |l| l.id == lease_id }
    raise NotFoundError, "Lease not found." unless lease
    Result.new(lease: lease)
  end
end
