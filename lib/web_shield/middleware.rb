module WebShield
  class Middleware
    def initialize(app, config)
      @app = app
      @config = config
    end

    def call(env)
      @app.call(env)
    end
  end
end

