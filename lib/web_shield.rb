require "web_shield/version"

require 'active_support'
require 'active_support/core_ext'

module WebShield
  extend ActiveSupport::Autoload

  class Error < StandardError; end

  autoload :Config
  autoload :MemoryStore
  autoload :Shield
  autoload :Middleware

  class << self
    attr_reader :config

    def configure(&block)
      @config = Config.new
      block.call(@config)
    end
  end
end
