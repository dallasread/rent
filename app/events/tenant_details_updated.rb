class TenantDetailsUpdated < RailsEventStore::Event
  # data: { application_id:, name:, new_mobile:, notes:, actor_id:, updated_at: }
  #
  # `actor_id`   is the User who performed the edit.
  # `new_mobile` is the tenant's updated phone number (subject, not actor).
  #
  # Tenants are derived from applicants (same id), but the *editable* details
  # belong to the tenant lifecycle (post-lease). `notes` is the editable,
  # landlord-managed field surfaced on the tenant page; the original applicant
  # `summary` (intake pitch) is preserved as immutable history.
end
