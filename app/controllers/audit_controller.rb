class AuditController < ApplicationController
  def index
    @result = AuditLog.call(
      entity_id: params[:entity_id],
      actor: params[:actor],
      event_type: params[:event_type]
    )
  end
end
