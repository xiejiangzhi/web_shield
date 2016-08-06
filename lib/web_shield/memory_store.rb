# Support data types:
#   String
#   Set
#

require 'monitor'
require 'set'

module WebShield
  class MemoryStore
    def initialize
      @data = {}
      @lock = Monitor.new
    end

    def set(key, value, options = {})
      set_data(key, value.to_s, options)
    end

    def get(key)
      val = get_data(key)
      val ? val.to_s : nil
    end

    def incr(key, options = {})
      @lock.synchronize do
        set_data(key, get_data(key).to_i + 1, options)
      end
    end

    def sadd(key, vals)
      key = key.to_sym
      values = vals.is_a?(Array) ? vals.map(&:to_s) : [vals.to_s]
      @lock.synchronize do
        @data[key] ||= Set.new
        @data[key].merge(values)
      end
      true
    end

    def srem(key, vals)
      key = key.to_sym
      key_data = @data[key]
      return false unless key_data && key_data.is_a?(Set)
      values = vals.is_a?(Array) ? vals.map(&:to_s) : [vals.to_s]
      @lock.synchronize do
        key_data.delete_if {|val| values.include?(val) }
      end
      true
    end

    def smembers(key)
      @data[key.to_sym] || Set.new
    end

    def sismember(key, val)
      set = @data[key.to_sym]
      return false unless set
      @data[key.to_sym].include?(val)
    end

    def reset(key)
      @data.delete(key.to_sym)
    end

    def clear
      @data.clear
    end


    private

    # Params:
    #   key: string or symbol
    #   value: any
    #   options:
    #     expire_at: Time or timestamp
    def set_data(key, value, expire_at: nil)
      key = key.to_sym
      ts = expire_at ? expire_at.to_i : nil

      (@data[key] = [value, ts]).first
    end

    def get_data(key)
      key = key.to_sym
      return nil unless @data[key]
      ts = Time.now.to_i

      if @data[key][1].nil? || @data[key][1] > ts
        @data[key][0]
      else
        @data.delete(key)
        nil
      end
    end
  end
end

