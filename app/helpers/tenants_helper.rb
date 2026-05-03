module TenantsHelper
  # Once an applicant has at least one lease they are a tenant; their canonical
  # page is then /tenants/:id, not /applicants/:id. Use this anywhere a person
  # is referenced from a lease, transaction, or other operational record so the
  # link points at the operational view (tenant), not the intake view (applicant).
  def tenant_link(applicant_id, fallback: "(deleted)")
    application = Applicant.call(applicant_id: applicant_id).application
    return fallback unless application

    link_to application.name, tenant_path(applicant_id)
  end
end
