module AuditHelper
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
