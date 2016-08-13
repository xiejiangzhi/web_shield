require 'digest'

module WebShield
  class Shield
    attr_reader :id, :shield_path, :path_matcher, :options, :config

    class << self
      def allowed_option_keys
        @allowed_option_keys ? @allowed_option_keys.dup : []
      end


      private

      def allow_option_keys(*keys)
        @allowed_option_keys = keys.map(&:to_sym)
      end
    end

    def initialize(id, shield_path, options, config)
      @id = id
      @shield_path = shield_path
      @path_matcher = build_path_matcher(shield_path)
      @options = hash_to_symbol_keys(options)
      @config = config

      check_options(@options)
    end

    # Returns: :pass, :block, [:response, rack_response], nil
    def filter(request)
      raise Error, "implement me"
    end

    def dictatorial?
      @options[:dictatorial]
    end

    def write_log(severity, msg)
      case svrt = severity.to_sym
      when :debug, :info, :warn, :error
        config.logger.send(svrt, "#{shield_name} #{msg}")
      else
        raise "Invalid log severity '#{svrt}'"
      end
    end

    def shield_name
      self.class.name.split('::', 2).last + "\##{id}"
    end

    private

    # Support symbols: :name, (), *
    def build_path_matcher(path)
      regexp_str = Regexp.escape(path)
      regexp_str.gsub!(/\\\((.+)\\\)/, '(\1)?')
      regexp_str.gsub!(/:[^\/\)]+(\)|\/)?/) {|str| "[^/]+#{$1 ? $1 : nil}" }
      regexp_str.gsub!(/\/$/, '/?')
      regexp_str.gsub!("\\*", '.*')
      Regexp.new("\\A#{regexp_str}\\z", 'i')
    end

    def hash_to_symbol_keys(hash)
      hash.each_with_object({}) do |kv, result|
        key, val = kv[0].to_sym, kv[1]
        result[key] = val
      end
    end

    def check_options(options)
      options.each do |key, val|
        unless self.class.allowed_option_keys.include?(key)
          raise Error, "Invalid shield option '#{key}'"
        end
      end
    end

    def generate_store_key(suffix)
     ['WS', "#{self.class.name.split('::').last}\##{id}", suffix.to_s].join(':')
    end
  end
end

