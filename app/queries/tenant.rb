class Tenant
  # The applicant + their leases. Read-only view; "becoming a tenant" happens
  # implicitly when a lease is created for an applicant.
  TenantDetail = Data.define(:applicant_id, :name, :mobile, :summary, :leases)
  Result = Data.define(:tenant)

  def self.call(tenant_id:)
    leases = Leases.call.leases.select { |l| l.applicant_id == tenant_id }
    return Result.new(tenant: nil) if leases.empty?

    a = Applicant.call(applicant_id: tenant_id).application
    return Result.new(tenant: nil) unless a

    Result.new(tenant: TenantDetail.new(
      applicant_id: tenant_id,
      name: a.name,
      mobile: a.mobile,
      summary: a.summary,
      leases: leases
    ))
  end
end
