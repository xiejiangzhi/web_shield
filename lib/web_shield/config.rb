require 'logger'

module WebShield
  class Config
    attr_accessor :store, :user_parser, :blocked_response, :logger
    attr_reader :shields

    def initialize
      @shields = []
      @shield_counter = 0

      @user_parser = Proc.new {|req| req.ip }
      @blocked_response = Proc.new {|req| [429, {}, ['Too Many Requests']] }
      @logger = Logger.new($stdout)
    end

    def store=(store)
      if store.respond_to?(:incr)
        @store = store
      else
        raise Error, 'Invalid store, interface :incr is need'
      end
    end

    def user_parser=(parser)
      if parser.respond_to?(:call)
        @user_parser = parser
      else
        raise Error, 'Invalid parser, interface :cal is need'
      end
    end

    def build_shield(path_matcher, options, shield_class = ThrottleShield)
      shields << shield_class.new(@shield_counter += 1, path_matcher, options, self)
      logger.info("Build shield #{shields.last.id} #{path_matcher} #{options}")
    end
  end
end

