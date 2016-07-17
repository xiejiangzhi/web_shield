require 'web_shield'

config = WebShield::Config.new
config.store = WebShield::MemoryStore.new # or WebShield::RedisStore.new(redis: Redis.current)

config.user_parser = Proc.new {|request| request.params[:token] || request.ip }

# filter order
$ip_shield = config.build_shield(
  "/api/ip*", {
    whitelist: %w{127.0.0.1},
    blacklist: %w{1.1.1.1}
  },
  WebShield::IPShield
)

config.build_shield "/api/ip*", {period: 5, limit: 3}

# dynamic add ips
$ip_shield.push_to_whitelist(%w{192.168.0.0/16 10.0.0.1/16})
$ip_shield.push_to_blacklist(%w{111.1.1.1/24 1.2.3.4})

$ip_config = config

