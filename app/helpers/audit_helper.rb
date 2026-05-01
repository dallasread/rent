module AuditHelper
  REDACTED_KEYS = %i[mobile code token].freeze

  def audit_value(key, value)
    case key.to_sym
    when :property_id  then audit_property_link(value)
    when :lease_id     then audit_lease_link(value)
    when :tx_id        then audit_tx_link(value)
    when :applicant_id then audit_applicant_link(value)
    when :tax_id       then audit_tax_link(value)
    when :tax_ids      then safe_join(Array(value).map { |id| audit_tax_link(id) }, ", ")
    else
      audit_scalar(value)
    end
  end

  def audit_scalar(value)
    case value
    when Hash    then value.inspect
    when Array   then value.join(", ")
    when Time    then value.iso8601
    when Date    then value.iso8601
    when Integer, Float, true, false then value.to_s
    when nil     then "—"
    else              value.to_s
    end
  end

  def audit_property_link(id)
    return "—" if id.blank?
    p = audit_properties_by_id[id]
    p ? link_to((p.address.presence || p.name), property_public_path(p.slug)) : "(deleted #{short_id(id)})"
  end

  def audit_lease_link(id)
    return "—" if id.blank?
    l = audit_leases_by_id[id]
    l ? link_to(applicant_name_lookup(l.applicant_id) || l.name, lease_path(l.id)) : "(deleted #{short_id(id)})"
  end

  def audit_tx_link(id)
    return "—" if id.blank?
    t = audit_transactions_by_id[id]
    t ? link_to(t.description.presence || "transaction", transaction_path(t.id)) : "(deleted #{short_id(id)})"
  end

  def audit_applicant_link(id)
    return "—" if id.blank?
    a = audit_applicants_by_id[id]
    a ? link_to(a.name, applicant_path(a.id)) : "(deleted #{short_id(id)})"
  end

  def audit_tax_link(id)
    return "—" if id.blank?
    t = audit_taxes_by_id[id]
    t ? link_to(t.label, edit_tax_path(t.id)) : "(deleted #{short_id(id)})"
  end

  def audit_properties_by_id
    @_audit_properties_by_id ||= Properties.call.properties.index_by(&:id)
  end

  def audit_leases_by_id
    @_audit_leases_by_id ||= Leases.call(include_archived: true).leases.index_by(&:id)
  end

  def audit_transactions_by_id
    @_audit_transactions_by_id ||= Transactions.call(include_archived: true).transactions.index_by(&:id)
  end

  def audit_applicants_by_id
    @_audit_applicants_by_id ||= Applications.call(include_archived: true).applications.index_by(&:id)
  end

  def audit_taxes_by_id
    @_audit_taxes_by_id ||= Taxes.call.taxes.index_by(&:id)
  end

  def applicant_name_lookup(id)
    audit_applicants_by_id[id]&.name
  end

  def short_id(id)
    id.to_s[0, 8]
  end

  def audit_details(entry)
    entry.data.reject { |k, _| REDACTED_KEYS.include?(k) || k.to_s.end_with?("_at") }
  end

  def audit_summary(entry)
    case entry.event_type
    when "PropertyAdded"        then "Added property “#{entry.data[:name]}”"
    when "PropertyUpdated"      then "Updated property “#{entry.data[:name]}”"
    when "PropertyRemoved"      then "Removed property"
    when "PropertyPublished"    then "Published property"
    when "PropertyUnpublished"  then "Unpublished property"
    when "ApplicationSubmitted" then "Submitted application: #{entry.data[:name]}"
    when "LeaseCreated"         then "Created lease"
    when "LeaseUpdated"         then "Updated lease"
    when "TransactionRecorded"  then "Recorded transaction: #{entry.data[:description]}"
    when "TransactionUpdated"   then "Updated transaction"
    when "TransactionMarkedPaid" then "Marked transaction as paid"
    when "LoginCodeRequested"   then "Requested login code"
    when "LoginCodeVerified"    then "Logged in"
    when "LoggedOut"            then "Logged out"
    when "UserPromotedToAdmin"  then "Promoted to admin"
    when "ApiTokenCreated"      then "Created API token “#{entry.data[:name]}”"
    when "ApiTokenRevoked"      then "Revoked API token"
    when "SettingsUpdated"      then "Updated settings"
    else                             entry.event_type.titleize
    end
  end
end
