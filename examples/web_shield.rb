require 'web_shield'

config = WebShield::Config.new
config.store = WebShield::MemoryStore.new # or WebShield::RedisStore.new(redis: Redis.current)

config.parse_user {|request| request.params[:token] || request.ip }
config.add_whitelist %w{127.0.0.1 192.168.0.0/16 123.123.123.123}
config.add_blacklist %w{111.111.111.111 222.222.222.222/8}

# filter order
config.build_shield '/api/v1/sessions', {
  period: 1.minutes, limit: 5, method: :post, skip_other_shields: true
}
config.build_shield '/api/v1/callbacks/app_store', {
  period: 10.seconds, limit: 1000, method: :post, skip_other_shields: true
}
config.build_shield '/api/v1/users/change_password', {
  period: 15.minutes, limit: 5, skip_other_shields: true
}

config.build_shield('/api/v1/*') do |request|
  if my_ip_pool.include?(request.ip)
    {period: 1.minutes, limit: 120}
  else
    {period: 1.minutes, limit: 60}
  end
end

config.build_shield('/api/v1/*') do |request|
  if my_ip_pool.include?(request.ip)
    {period: 3.minutes, limit: 240}
  else
    {period: 3.minutes, limit: 120}
  end
end

config.build_shield('/api/v1/*') do |request|
  if my_ip_pool.include?(request.ip)
    {period: 15.seconds, limit: 5, path_sensitive: true}
  else
    {period: 15.seconds, limit: 5, path_sensitive: true}
  end
end

class RackBenchmark
  def initialize(app)
    @app = app
  end

  def call(env)
    s = Time.now
    @app.call(env).tap { puts "#{(Time.now - s) * 1000} ms"  }
  end
end


Benchmark = Rack::Builder.new do
  use RackBenchmark

  app = Proc.new {|env| [200, {'Content-Type' => 'text/html'}, ['Hello WebShield']] }

  map '/web_shield' do
    use WebShield::Middleware, config
    run app
  end

  map '/normal' do
    run app
  end
end.to_app

