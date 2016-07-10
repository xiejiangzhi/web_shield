require 'digest'

module WebShield
  class Shield
    attr_reader :id, :shield_path, :path_matcher, :options, :config
    OPTION_KEYS =[:period, :limit, :method, :path_sensitive, :dictatorial]

    # Params:
    #   path:
    #   options:
    #     period: required
    #     limit: required
    #     method: optional
    #     path_sensitive: optional, defualt false
    def initialize(id, shield_path, options, config)
      @id = id
      @shield_path = shield_path
      @path_matcher = build_path_matcher(shield_path)
      @options = hash_to_symbol_keys(options)
      @config = config
    end

    # Returns: :pass, :block, [:response, rack_response], nil
    def filter(request)
      raise Error, "implement me"
    end

    def dictatorial?
      @options[:dictatorial]
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
        raise Error, "Invalid shield option '#{key}'" unless OPTION_KEYS.include?(key)
        result[key] = val
      end
    end
  end
end

