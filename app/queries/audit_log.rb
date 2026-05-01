class AuditLog
  ID_KEYS = %i[property_id lease_id tx_id application_id tenant_id token_id user_id applicant_id].freeze
  PER_PAGE = 50

  Entry = Data.define(:event_id, :event_type, :actor, :occurred_at, :data)
  Result = Data.define(:entries, :event_types, :page, :per_page, :has_next?)

  def self.call(entity_id: nil, actor: nil, event_type: nil, page: 1)
    page = [ page.to_i, 1 ].max

    events = Rails.configuration.event_store.read.backward.to_a

    entries = events.map do |e|
      Entry.new(
        event_id: e.event_id,
        event_type: e.event_type.to_s,
        actor: e.data[:mobile].to_s.presence || "system",
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
      entries = entries.select { |entry| entry.actor == actor }
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
end
