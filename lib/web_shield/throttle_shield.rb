require 'digest'

module WebShield
  class ThrottleShield < Shield

    def filter(request)
      req_path = request.path
      return unless path_matcher.match(req_path)
      return :block if options[:limit] <= 0
      return if options[:method] && options[:method].to_s.upcase != request.request_method

      user = config.user_parser.call(request)
      store_keys = [id.to_s, user.to_s]
      if options[:path_sensitive]
        route = [request.request_method, req_path]
      else
        route = (options[:method] ? [options[:method].to_s.upcase, shield_path] : [shield_path])
      end
      store_keys << Digest::MD5.hexdigest(route.join('-'))

      if @config.store.incr(store_keys.join('-'), options[:period]) <= options[:limit]
        :pass
      else
        config.logger.info("[#{id}] Block '#{user}' #{request.request_method} #{req_path}")
        :block
      end
    end
  end
end

