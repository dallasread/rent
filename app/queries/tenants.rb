class Tenants
  TenantView = Data.define(:applicant_id, :name, :mobile, :property_ids, :current_leases, :active?) do
    def id
      applicant_id
    end

    def lease_count
      current_leases.size
    end
  end

  Result = Data.define(:tenants)

  def self.call(include_inactive: false, as_of: Date.current)
    leases = Leases.call(include_archived: true).leases
    return Result.new(tenants: []) if leases.empty?

    by_applicant = leases.group_by(&:applicant_id)
    applicants = Applications.call.applications.index_by(&:id)

    tenants = by_applicant.map do |applicant_id, applicant_leases|
      a = applicants[applicant_id]
      current = applicant_leases.select { |l| l.active_on?(as_of) }
      surfaced = current.any? ? current : applicant_leases
      TenantView.new(
        applicant_id: applicant_id,
        name: a&.name || "(deleted applicant)",
        mobile: a&.mobile,
        property_ids: surfaced.map(&:property_id).uniq,
        current_leases: surfaced,
        active?: current.any?
      )
    end

    tenants = tenants.select(&:active?) unless include_inactive
    Result.new(tenants: tenants.sort_by { |t| t.name.to_s.downcase })
  end
end
