module WebShield
  class CreditAnalyzer
    attr_reader :config, :credit_shield, :options

    def initialize(credit_shield)
      @credit_shield = credit_shield
      @config = credit_shield.config
      @options = credit_shield.options
    end

    def analyze(ip, user, header, params)
      # TODO
    end


    private

    def update_ip_credit(ip, revise_val)
      credit_key = credit_shield.get_credit_key(:ip, ip)
      config.store.incr(credit_key, increment: revise_val)
    end

    def update_user_credit(user, revise_val)
      credit_key = credit_shield.get_credit_key(:u, user)
      config.store.incr(credit_key, increment: revise_val)
    end
  end
end

