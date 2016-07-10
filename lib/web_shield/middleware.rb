require 'rack'

module WebShield
  class Middleware
    def initialize(app, config)
      @app = app
      @config = config
    end

    def call(env)
      request = Rack::Request.new(env)

      @config.shields.each do |shield|
        result, response = shield.filter(request)

        case result
        when :block
          return @config.blocked_response.call(request)
        when :response
          return response
        when :pass
          if shield.dictatorial?
            # skip other shields
            return @app.call(env)
          end
        else
          # not match
        end
      end

      @app.call(env)
    end
  end
end

