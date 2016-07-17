require 'monitor'
require 'set'

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

    def push_to_set(key, vals)
      values = vals.is_a?(Array) ? vals.map(&:to_s) : [vals.to_s]
      @lock.synchronize do
        @data[key] ||= Set.new
        @data[key].merge(values)
      end
      true
    end

    def del_from_set(key, vals)
      key_data = @data[key]
      return false unless key_data && key_data.is_a?(Set)
      values = vals.is_a?(Array) ? vals.map(&:to_s) : [vals.to_s]
      @lock.synchronize do
        key_data.delete_if {|val| values.include?(val) }
      end
      true
    end

    def read_set(key)
      @data[key] || Set.new
    end

    def reset(key)
      @data.delete(key.to_sym)
    end

    def clear
      @data.clear
    end
  end
end

