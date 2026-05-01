class Tenants
  TenantView = Data.define(:applicant_id, :name, :mobile, :property_ids) do
    def id
      applicant_id
    end

    def lease_count
      property_ids.size
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
        property_ids: applicant_leases.map(&:property_id).uniq
      )
    end.sort_by { |t| t.name.to_s.downcase }

    Result.new(tenants: tenants)
  end
end
