class HttpBasicAuth
  def initialize(app, password:)
    @app = app
    @password = password
  end

  def call(env)
    return deny if @password.to_s.empty?

    request = Rack::Auth::Basic::Request.new(env)
    if request.provided? && request.basic? && request.credentials &&
       ActiveSupport::SecurityUtils.secure_compare(request.credentials[1].to_s, @password)
      @app.call(env)
    else
      deny
    end
  end

  private

  def deny
    [
      401,
      { "WWW-Authenticate" => 'Basic realm="Restricted"', "Content-Type" => "text/plain" },
      [ "Authentication required\n" ]
    ]
  end
end
