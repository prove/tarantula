=begin rdoc

A rack middleware for handling authentication.

=end
class Authenticator

  UnAuthenticated = /^(\/home\/login|\/home\/logout|\/password_resets.*|\/assets.*)$/
  BasicAuthenticated = /^(\/api.*)$/
  ######
  class SessionAuth < Rack::Auth::AbstractHandler

    def initialize(app, realm=nil, &authenticator)
      @app = app
    end

    def call(env)
      return unauthorized(env) unless User.find_by_id(env['rack.session'][:user_id])
      @app.call(env)
    end

    private
    def unauthorized(env)
      [ 302, {'Content-type' => 'text/plain', 'Location' => env['SCRIPT_NAME'] + '/home/login',
              'Content-length' => '0'}, []]
    end
  end
  #####
  ######
  class BasicAuth < Rack::Auth::Basic

    def initialize(app, realm=nil, &authenticator)
      @app = app
    end

    def call(env)
			@auth ||=  BasicAuth::Request.new(env)
			if @auth.provided? && @auth.basic? && @auth.credentials && @auth.credentials == ['admin', 'admin']
				@app.call(env)
			else
				return unauthorized(env)
			end
    end

    private
    def unauthorized(env)
      [ 302, {'Content-type' => 'text/plain', 'Location' => env['SCRIPT_NAME'] + '/home/login',
              'Content-length' => '0'}, []]
    end
  end
  #####


  def initialize(app, realm=nil)
    @app = app
    @realm = realm
    @auths = [SessionAuth.new(app, realm){},BasicAuth.new(app, realm){}]
  end

  def session_auth(env)
    @auths[0]
  end
  def basic_auth(env)
    @auths[1]
  end

  def call(env)
    if env["PATH_INFO"] =~ UnAuthenticated
      @app.call(env)
		elsif env["PATH_INFO"] =~ BasicAuthenticated
      basic_auth(env).call(env)
		else
      session_auth(env).call(env)
    end
  end

end
