require 'digest'
require 'ipaddr'

module WebShield
  class IPShield < Shield
    OPTION_KEYS =[:whitelist, :blacklist]

    # Params:
    #   path:
    #   options:
    #     whitelist: options, defualt [], like 172.10.10.10 172.10.10.10/16
    #     blacklist: options, default [], like 172.10.10.10 172.10.10.10/16
    def initialize(id, shield_path, options, config)
      super

      check_options(@options)
      @options[:dictatorial] = true
      push_to_whitelist(options[:whitelist]) if options[:whitelist]
      push_to_blacklist(options[:blacklist]) if options[:blacklist]
    end

    def filter(request)
      req_path = request.path
      return unless path_matcher.match(req_path)

      if in_blacklist?(request.ip)
        user = config.user_parser.call(request)
        write_log(:info, "Blacklist block '#{user}' #{request.request_method} #{req_path}")
        :block
      elsif in_whitelist?(request.ip)
        write_log(:info, "Whitelist pass '#{user}' #{request.request_method} #{req_path}")
        :pass
      else
        nil
      end
    end

    def in_whitelist?(ip)
      in_ip_list?(get_store_key('whitelist'), ip)
    end

    def in_blacklist?(ip)
      in_ip_list?(get_store_key('blacklist'), ip)
    end

    def push_to_whitelist(ips)
      config.store.sadd(get_store_key('whitelist'), ips)
    end

    def push_to_blacklist(ips)
      config.store.sadd(get_store_key('blacklist'), ips)
    end


    private

    # TODO optimize it
    def in_ip_list?(list_key, ip)
      config.store.smembers(list_key).any? {|ip_range| IPAddr.new(ip_range).include?(ip) }
    end

    def get_store_key(list_name)
      ['web_shield', 'ip_shield', list_name].join('/')
    end

    def check_options(options)
      options.each do |key, val|
        raise Error, "Invalid shield option '#{key}'" unless OPTION_KEYS.include?(key)
      end
    end
  end
end

