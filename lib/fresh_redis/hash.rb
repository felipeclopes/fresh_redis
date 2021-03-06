class FreshRedis
  module Hash

    def fhset(key, hash_key, value, options={})
      key = build_key(key, options)
      @redis.multi do
        @redis.hset(key.redis_key, hash_key, value)
        @redis.expire(key.redis_key, key.freshness)
      end
    end

    def fhget(key, hash_key, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined {
        key.timestamp_buckets.reverse.each do |bucket_key|
          @redis.hget(bucket_key, hash_key)
        end
      }

      # find the first non-nil value
      bucket_values.find{|e| e } 
    end

    def fhgetall(key, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined {
        key.timestamp_buckets.each do |bucket_key|
          @redis.hgetall(bucket_key)
        end
      }

      merged_values = bucket_values.inject({}){ |acc, bucket_hash|
        acc.merge(bucket_hash)
      }

      merged_values.reject{ |key, value| !value }
    end

    def fhdel(key, hash_key, options={})
      key = build_key(key, options)

      bucket_values = @redis.pipelined {
        key.timestamp_buckets.each do |bucket_key|
          @redis.hdel(bucket_key, hash_key)
        end
      }
    end
  end
end
