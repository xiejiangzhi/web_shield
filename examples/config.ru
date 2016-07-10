#\ -s webrick

require 'pry'
require File.expand_path('../base_config', __FILE__)
require File.expand_path('../more_shields_config', __FILE__)

class RackBenchmark
  def initialize(app)
    @app = app
    @counter = {}
  end

  def call(env)
    $req = request = Rack::Request.new(env)
    s = Time.now
    @app.call(env).tap do
      cost = (Time.now - s) * 1000
      path_counter = @counter[request.path] ||= [0, 0]
      path_counter[0] += 1
      path_counter[1] += cost
      puts "#{cost} ms, avg #{path_counter[1] / path_counter[0]} ms"
    end
  end
end

use RackBenchmark

app = Proc.new {|env| [200, {'Content-Type' => 'text/html'}, ['Hello WebShield']] }

map '/normal' do
  run app
end

map '/api/v1' do
  use WebShield::Middleware, $base_config
  run app
end

map '/api/v2' do
  use WebShield::Middleware, $more_shields_config
  run app
end

