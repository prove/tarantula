=begin rdoc

A rack middleware for handling authentication.

=end
class Authenticator

  UnAuthenticated = /^(\/home\/login|\/home\/logout|\/password_resets.*|\/assets.*)$/
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


  def initialize(app, realm=nil)
    @app = app
    @realm = realm
    @auths = [SessionAuth.new(app, realm){}]
  end

  def select_auth(env)
    @auths.first
  end

  def call(env)
    if env["PATH_INFO"] =~ UnAuthenticated
      @app.call(env)
    else
      select_auth(env).call(env)
    end
  end

end
