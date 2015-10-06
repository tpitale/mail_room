require "redis"

module MailRoom
  module Arbitration
    class Redis
      Options = Struct.new(:redis_url, :namespace) do
        def initialize(mailbox)
          redis_url = mailbox.arbitration_options[:redis_url] || "redis://localhost:6379"
          namespace = mailbox.arbitration_options[:namespace]

          super(redis_url, namespace)
        end
      end

      # Expire after 10 minutes so Redis doesn't get filled up with outdated data.
      EXPIRATION = 600

      attr_accessor :options

      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Delivery::Sidekiq::Options]
      def initialize(options)
        @options = options
      end

      def deliver?(message)
        uid = message.attr["UID"]
        key = "delivered:#{uid}"

        incr = nil
        redis.multi do |client|
          # At this point, `incr` is a future, which will get its value after 
          # the MULTI command returns.
          incr = client.incr(key)

          client.expire(key, EXPIRATION)
        end

        # If INCR returns 1, that means the key didn't exist before, which means
        # we are the first mail_room to try to deliver this message, so we get to.
        # If we get any other value, another mail_room already (tried to) deliver
        # the message, so we don't have to anymore.
        incr.value == 1
      end

      private

      def redis
        @redis ||= begin
          redis = ::Redis.new(url: options.redis_url)

          namespace = options.namespace
          if namespace
            require 'redis/namespace'
            ::Redis::Namespace.new(namespace, redis: redis)
          else
            redis
          end
        end
      end
    end
  end
end
