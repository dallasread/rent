# Single source of truth for who can do what.
#
# Keys are either:
#   - Command class names         (e.g. "AddProperty")        — checked from commands
#   - "Controller#action" pairs   (e.g. "Properties#index")   — checked from controllers
#
# Roles:
#   :public         no actor needed (login flows, public show)
#   :authenticated  any signed-in mobile
#   :admin          must be marked admin (UserPromotedToAdmin event)
module Authorization
  class Unauthenticated < CommandError; end
  class Forbidden < CommandError; end

  POLICIES = {
    # Commands
    "RequestLoginCode"  => :public,
    "VerifyLoginCode"   => :public,
    "LogOut"            => :public,
    "AddProperty"       => :admin,
    "UpdateProperty"    => :admin,
    "RemoveProperty"    => :admin,
    "DuplicateProperty" => :admin,
    "PublishProperty"   => :admin,
    "UnpublishProperty" => :admin,
    "SubmitApplication" => :public,
    "AddApplicant"      => :admin,
    "ArchiveApplicant"  => :admin,
    "UnarchiveApplicant" => :admin,
    "CreateLease"       => :admin,
    "UpdateLease"       => :admin,
    "ArchiveLease"      => :admin,
    "UnarchiveLease"    => :admin,
    "RecordTransaction" => :admin,
    "UpdateTransaction" => :admin,
    "MarkTransactionPaid" => :admin,
    "ArchiveTransaction" => :admin,
    "UnarchiveTransaction" => :admin,
    "CreateApiToken"    => :admin,
    "RevokeApiToken"    => :admin,
    "UpdateSettings"    => :admin,
    "AddTax"            => :admin,
    "UpdateTax"         => :admin,

    # Controller actions
    "Logins#new"           => :public,
    "Logins#create"        => :public,
    "Logins#verify"        => :public,
    "Logins#submit"        => :public,
    "Sessions#destroy"     => :public,
    "Dashboard#show"       => :authenticated,
    "Properties#show"      => :public,
    "Properties#index"     => :admin,
    "Properties#new"       => :admin,
    "Properties#create"    => :admin,
    "Properties#edit"      => :admin,
    "Properties#update"    => :admin,
    "Properties#destroy"   => :admin,
    "Properties#duplicate" => :admin,
    "Properties#publish"   => :admin,
    "Properties#unpublish" => :admin,
    "Applicants#index"     => :admin,
    "Applicants#show"      => :admin,
    "Applicants#new"       => :admin,
    "Applicants#create"    => :admin,
    "Applicants#apply"     => :public,
    "Applicants#submit"    => :public,
    "Applicants#archive"   => :admin,
    "Applicants#unarchive" => :admin,
    "Leases#index"         => :admin,
    "Leases#show"          => :admin,
    "Leases#new"           => :admin,
    "Leases#create"        => :admin,
    "Leases#edit"          => :admin,
    "Leases#update"        => :admin,
    "Leases#archive"       => :admin,
    "Leases#unarchive"     => :admin,
    "Tenants#index"        => :admin,
    "Tenants#show"         => :admin,
    "RentRoll#show"        => :admin,
    "RentRoll#record"      => :admin,
    "Transactions#index"   => :admin,
    "Transactions#show"    => :admin,
    "Transactions#new"     => :admin,
    "Transactions#create"  => :admin,
    "Transactions#edit"    => :admin,
    "Transactions#update"  => :admin,
    "Transactions#mark_paid" => :admin,
    "Transactions#archive"   => :admin,
    "Transactions#unarchive" => :admin,
    "ApiTokens#index"      => :admin,
    "ApiTokens#new"        => :admin,
    "ApiTokens#create"     => :admin,
    "ApiTokens#destroy"    => :admin,
    "ApiDocs#show"         => :public,
    "Settings#show"        => :admin,
    "Settings#update"      => :admin,
    "Taxes#index"          => :admin,
    "Taxes#new"            => :admin,
    "Taxes#create"         => :admin,
    "Taxes#edit"           => :admin,
    "Taxes#update"         => :admin,
    "Audit#index"          => :admin
  }.freeze

  def self.check!(actor:, key:)
    role = POLICIES.fetch(key) do
      raise "No ACL policy for #{key.inspect}. Add it to Authorization::POLICIES."
    end

    case role
    when :public
      true
    when :authenticated
      raise Unauthenticated, "Sign in required." if actor.blank?
      true
    when :admin
      raise Unauthenticated, "Sign in required." if actor.blank?
      raise Forbidden, "Admin access required." unless IsAdmin.call(mobile: actor).admin?
      true
    else
      raise "Unknown ACL role #{role.inspect} for #{key.inspect}."
    end
  end
end
