class Tenants
  # A "tenant" is an applicant who has at least one lease. This is purely a
  # derived view — there's no TenantAdded event. State comes from joining
  # Applications and Leases.
  TenantView = Data.define(:applicant_id, :name, :mobile, :lease_count) do
    def id
      applicant_id
    end
  end

  Result = Data.define(:tenants)

  def self.call
    leases = Leases.call.leases
    return Result.new(tenants: []) if leases.empty?

    by_applicant = leases.group_by(&:applicant_id)
    applicants = Applications.call.applications.index_by(&:id)

    tenants = by_applicant.map do |applicant_id, applicant_leases|
      a = applicants[applicant_id]
      TenantView.new(
        applicant_id: applicant_id,
        name: a&.name || "(deleted applicant)",
        mobile: a&.mobile,
        lease_count: applicant_leases.size
      )
    end.sort_by { |t| t.name.to_s.downcase }

    Result.new(tenants: tenants)
  end
end
