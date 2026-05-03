class Tenant
  TenantDetail = Data.define(:applicant_id, :name, :mobile, :summary, :leases)
  Result = Data.define(:tenant)

  def self.call(tenant_id:)
    leases = Leases.call(include_archived: true).leases.select { |l| l.applicant_id == tenant_id }
    raise NotFoundError, "Tenant not found." if leases.empty?

    a = Applicant.call(applicant_id: tenant_id).application

    Result.new(tenant: TenantDetail.new(
      applicant_id: tenant_id,
      name: a.name,
      mobile: a.mobile,
      summary: a.summary,
      leases: leases
    ))
  end
end
