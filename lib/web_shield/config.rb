module WebShield
  class Config
    attr_accessor :store, :user_parser
    attr_reader :shields, :plugins, :ip_whitelist, :ip_blacklist

    def initialize
      @shields = []
      @plugins = []
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

    def build_shield(path_matcher, options = nil, &block)
      raise Error, 'Need options or block' unless options || block
      shields << [path_matcher, options, block]
    end

    def use(plugin, options = nil, &block)
      raise Error, 'Need a plugin class' unless plugin.respond_to?(:new)
      plugins.delete_if {|p, _, _| p == plugin }
      plugins << [plugin, options, block]
    end
  end
end

