class TenantsController < ApplicationController
  def index
    @result = Tenants.call
  end

  def show
    @tenant = Tenant.call(tenant_id: params[:id]).tenant
  end
end
