require "web_shield/version"

require 'rack'
# require 'active_support'
# require 'active_support/core_ext'

module WebShield
  class Error < StandardError; end

  autoload :Config, 'web_shield/config'

  autoload :MemoryStore, 'web_shield/memory_store'

  autoload :Shield, 'web_shield/shield'
  autoload :ThrottleShield, 'web_shield/throttle_shield'
  autoload :IPShield, 'web_shield/ip_shield'
  autoload :CreditShield, 'web_shield/credit_shield'
  autoload :CreditAnalyzer, 'web_shield/credit_analyzer'

  autoload :Middleware, 'web_shield/middleware'

  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new
      block.call(@config)
    end
  end
end
