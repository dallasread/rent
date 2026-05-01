class TenantsController < ApplicationController
  def index
    @show_inactive = params[:inactive] == "1"
    @result = Tenants.call(include_inactive: @show_inactive)
  end

  def show
    @tenant = Tenant.call(tenant_id: params[:id]).tenant
  end
end
