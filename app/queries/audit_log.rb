class AuditLog
  ID_KEYS = %i[property_id lease_id tx_id application_id tenant_id token_id user_id applicant_id].freeze
  PER_PAGE = 50

  # `actor` is the displayable mobile (resolved from actor_id via the User
  # aggregate). `actor_id` is the raw UUID stored on the event.
  Entry = Data.define(:event_id, :event_type, :actor, :actor_id, :occurred_at, :data)
  Result = Data.define(:entries, :event_types, :page, :per_page, :has_next?)

  def self.call(entity_id: nil, actor: nil, event_type: nil, page: 1)
    page = [ page.to_i, 1 ].max

    events = Rails.configuration.event_store.read.backward.to_a
    users_by_id = Users.call.users.index_by(&:id)

    entries = events.map do |e|
      actor_id = actor_id_for(e)
      mobile   = users_by_id[actor_id]&.mobile
      Entry.new(
        event_id: e.event_id,
        event_type: e.event_type.to_s,
        actor: mobile.presence || (actor_id == "system" ? "system" : actor_id) || "system",
        actor_id: actor_id,
        occurred_at: e.metadata[:timestamp],
        data: e.data
      )
    end

    if entity_id.present?
      entries = entries.select do |entry|
        ID_KEYS.any? { |k| entry.data[k].to_s == entity_id }
      end
    end

    if actor.present?
      target_user = users_by_id.values.find { |u| u.mobile == actor }
      target_id = target_user&.id || actor
      entries = entries.select { |entry| entry.actor_id == target_id }
    end

    if event_type.present?
      entries = entries.select { |entry| entry.event_type == event_type }
    end

    types = events.map(&:event_type).map(&:to_s).uniq.sort
    offset = (page - 1) * PER_PAGE
    paged = entries.drop(offset).first(PER_PAGE)

    Result.new(
      entries: paged,
      event_types: types,
      page: page,
      per_page: PER_PAGE,
      has_next?: entries.size > offset + PER_PAGE
    )
  end

  # The actor of an event lives in different fields depending on the event:
  #   - actor_id        : the standard "who did this" UUID on every command-issued event
  #   - user_id         : LoginCodeVerified, UserCreated — the user is the subject and
  #                       (for verify) effectively the actor of the login
  #   - mobile          : LoginCodeRequested — pre-auth, no user yet; the mobile is the actor
  def self.actor_id_for(event)
    event.data[:actor_id] || event.data[:user_id] || event.data[:mobile]
  end
end
