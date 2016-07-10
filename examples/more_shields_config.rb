require 'web_shield'

config = WebShield::Config.new
config.store = WebShield::MemoryStore.new # or WebShield::RedisStore.new(redis: Redis.current)

config.user_parser = Proc.new {|request| request.params[:token] || request.ip }

base_path = '/api/v2'

100.times do |i|
  config.build_shield "#{base_path}/#{i}", {
    period: 10, limit: 3, dictatorial: true
  }
end

config.build_shield "#{base_path}/callbacks/app_store", {
  period: 10, limit: 5, dictatorial: true
}
config.build_shield "#{base_path}/callbacks/alipay", {
  period: 10, limit: 6, dictatorial: true
}
config.build_shield "#{base_path}/callbacks/xyz", {
  period: 10, limit: 4, dictatorial: true
}
config.build_shield "#{base_path}/users/change_password", {
  period: 15, limit: 3, dictatorial: true
}
config.build_shield "#{base_path}/*", {period: 10, limit: 3}
config.build_shield "#{base_path}/config", {period: 10, limit: 2}
config.build_shield "#{base_path}//test", {period: 0, limit: 3}

$more_shields_config = config

