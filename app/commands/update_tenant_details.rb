class UpdateTenantDetails
  class InvalidName < CommandError; end
  class InvalidMobile < CommandError; end

  def self.call(tenant_id:, actor:, name:, mobile:, notes: nil)
    Authorization.check!(actor: actor, key: self.name)
    Tenant.call(tenant_id: tenant_id) # raises if not found

    raise InvalidName, "Name is required." if name.to_s.strip.empty?
    normalized_mobile = Mobile.normalize(mobile)
    raise InvalidMobile, "Invalid mobile number." unless normalized_mobile

    Rails.configuration.event_store.publish(
      TenantDetailsUpdated.new(data: {
        application_id: tenant_id,
        name: name.to_s.strip,
        new_mobile: normalized_mobile,
        notes: notes.to_s.strip,
        mobile: actor,
        updated_at: Time.current
      }),
      stream_name: "Tenant$#{tenant_id}"
    )
    nil
  end
end
