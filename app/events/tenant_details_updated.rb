class TenantDetailsUpdated < RailsEventStore::Event
  # data: { application_id:, name:, new_mobile:, notes:, mobile:, updated_at: }
  #
  # `mobile`     is the *actor* (admin who performed the edit), matching the
  #              `mobile` convention used across all other events for actor.
  # `new_mobile` is the tenant's updated phone number.
  #
  # Tenants are derived from applicants (same id), but the *editable* details
  # belong to the tenant lifecycle (post-lease). `notes` is the editable,
  # landlord-managed field surfaced on the tenant page; the original applicant
  # `summary` (intake pitch) is preserved as immutable history.
end
