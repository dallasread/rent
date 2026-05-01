class TenantsController < ApplicationController
  def index
    @show_inactive = params[:inactive] == "1"
    @result = Tenants.call(include_inactive: @show_inactive)
    respond_to do |format|
      format.html
      format.json { render json: { tenants: @result.tenants.map(&:to_h) } }
    end
  end

  def show
    @tenant = Tenant.call(tenant_id: params[:id]).tenant
    respond_to do |format|
      format.html
      format.json { render json: { tenant: @tenant.to_h } }
    end
  end
end
