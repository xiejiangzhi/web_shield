require 'monitor'

module WebShield
  class MemoryStore
    def initialize
      @data = {}
      @lock = Monitor.new
    end

    def incr(key, period = 0)
      key = key.to_sym
      current_period = period > 0 ? (Time.now.to_i / period) : 0

      @lock.synchronize do
        if @data[key]
          if @data[key][1] == current_period
            @data[key][0] += 1
          else
            @data[key][1] = current_period
            @data[key][0] = 1
          end
        else
          @data[key] = [1, current_period]
          1
        end
      end
    end

    def reset(key)
      @data.delete(key.to_sym)
    end

    def clear
      @data.clear
    end
  end
end

