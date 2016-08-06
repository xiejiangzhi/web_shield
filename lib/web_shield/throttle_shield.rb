require 'digest'

module WebShield
  class ThrottleShield < Shield
    OPTION_KEYS =[:period, :limit, :method, :path_sensitive, :dictatorial]

    # Params:
    #   path:
    #   options:
    #     period: required
    #     limit: required
    #     method: optional
    #     path_sensitive: optional, defualt false
    def initialize(id, shield_path, options, config)
      super

      check_options(@options)
    end

    def filter(request)
      req_path = request.path
      return unless path_matcher.match(req_path)
      return :block if options[:limit] <= 0
      return if options[:method] && options[:method].to_s.upcase != request.request_method

      user = config.user_parser.call(request)

      incr_opts = if (period = options[:period]) > 0
        {expire_at: (Time.now.to_i / period + 1).to_i * period}
      else
        {}
      end

      if @config.store.incr(get_store_key(request, user), incr_opts) <= options[:limit]
        write_log(:debug, "Pass '#{user}' #{request.request_method} #{req_path}")
        :pass
      else
        write_log(:info, "Block '#{user}' #{request.request_method} #{req_path}")
        :block
      end
    end


    private

    def get_store_key(request, user)
      keys = ['web_shield', id.to_s, user.to_s]
      route = if options[:path_sensitive]
        [request.request_method, request.path]
      else
        (options[:method] ? [options[:method].to_s.upcase, shield_path] : [shield_path])
      end
      keys << Digest::MD5.hexdigest(route.join('-'))
      keys.join('/')
    end

    def check_options(options)
      options.each do |key, val|
        raise Error, "Invalid shield option '#{key}'" unless OPTION_KEYS.include?(key)
      end
    end
  end
end

