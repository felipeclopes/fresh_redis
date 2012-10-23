class FreshRedis
  module String
    def fincr(key, options={})
      key = build_key(key, options)
      @redis.multi do
        @redis.incr(key.redis_key)
        @redis.expire(key.redis_key, key.freshness)
      end
    end

    def fdecr(key, options={})
      key = build_key(key, options)
      @redis.multi do
        @redis.decr(key.redis_key)
        @redis.expire(key.redis_key, key.freshness)
      end
    end

    def fsum(key, options={})
      key = build_key(key, options)
      @redis.pipelined {
        key.timestamp_buckets.each do |bucket_key|
          @redis.get(bucket_key)
        end
      }.reduce(0){|acc, value|
        value ? acc + value.to_i : acc
      }
    end
  end
end
