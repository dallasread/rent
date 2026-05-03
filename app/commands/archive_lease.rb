class ArchiveLease
  class NotFound < NotFoundError; end

  def self.call(lease_id:, actor:)
    Authorization.check!(actor: actor, key: self.name)
    raise NotFound, "Lease not found." unless Lease.call(lease_id: lease_id).lease

    Rails.configuration.event_store.publish(
      LeaseArchived.new(data: {
        lease_id: lease_id,
        actor_id: actor,
        archived_at: Time.current
      }),
      stream_name: "Lease$#{lease_id}"
    )
    nil
  end
end
