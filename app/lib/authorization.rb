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
    "CreateLease"       => :admin,
    "RecordTransaction" => :admin,
    "MarkTransactionPaid" => :admin,
    "CreateApiToken"    => :admin,
    "RevokeApiToken"    => :admin,

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
    "Leases#index"         => :admin,
    "Leases#show"          => :admin,
    "Leases#new"           => :admin,
    "Leases#create"        => :admin,
    "Transactions#index"   => :admin,
    "Transactions#show"    => :admin,
    "Transactions#new"     => :admin,
    "Transactions#create"  => :admin,
    "Transactions#mark_paid" => :admin,
    "ApiTokens#index"      => :admin,
    "ApiTokens#new"        => :admin,
    "ApiTokens#create"     => :admin,
    "ApiTokens#destroy"    => :admin,
    "ApiDocs#show"         => :public
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
