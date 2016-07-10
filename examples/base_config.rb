require 'web_shield'

config = WebShield::Config.new
config.store = WebShield::MemoryStore.new # or WebShield::RedisStore.new(redis: Redis.current)

config.user_parser = Proc.new {|request| request.params[:token] || request.ip }

base_path = '/api/v1'

# filter order
config.build_shield "#{base_path}/sessions", {period: 10, limit: 3, dictatorial: true}
config.build_shield "#{base_path}/callbacks/app_store", {period: 10, limit: 5, dictatorial: true}
config.build_shield "#{base_path}/callbacks/alipay", {period: 10, limit: 6, dictatorial: true}
config.build_shield "#{base_path}/callbacks/xyz", {period: 10, limit: 4, dictatorial: true}
config.build_shield "#{base_path}/users/change_password", {
  period: 15, limit: 3, dictatorial: true, method: :post
}
config.build_shield "#{base_path}/*", {period: 10, limit: 3, path_sensitive: true}
config.build_shield "/api/config", {period: 10, limit: 2}
config.build_shield "/api/test", {period: 0, limit: 3}

$base_config = config

