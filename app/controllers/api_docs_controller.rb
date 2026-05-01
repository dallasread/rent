class ApiDocsController < ApplicationController
  def show
    @host = request.protocol + request.host_with_port
  end
end
