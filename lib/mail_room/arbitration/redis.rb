require "redis"

module MailRoom
  module Arbitration
    class Redis
      Options = Struct.new(:redis_url, :namespace, :sentinels) do
        def initialize(mailbox)
          redis_url = mailbox.arbitration_options[:redis_url] || "redis://localhost:6379"
          namespace = mailbox.arbitration_options[:namespace]
          sentinels = mailbox.arbitration_options[:sentinels]

          super(redis_url, namespace, sentinels)
        end
      end

      # Expire after 10 minutes so Redis doesn't get filled up with outdated data.
      EXPIRATION = 600

      attr_accessor :options

      def initialize(options)
        @options = options
      end

      def deliver?(uid)
        key = "delivered:#{uid}"

        incr = nil
        client.multi do |c|
          # At this point, `incr` is a future, which will get its value after
          # the MULTI command returns.
          incr = c.incr(key)

          c.expire(key, EXPIRATION)
        end

        # If INCR returns 1, that means the key didn't exist before, which means
        # we are the first mail_room to try to deliver this message, so we get to.
        # If we get any other value, another mail_room already (tried to) deliver
        # the message, so we don't have to anymore.
        incr.value == 1
      end

      private

      def client
        @client ||= begin
          sentinels = options.sentinels
          redis_options = { url: options.redis_url }
          redis_options[:sentinels] = sentinels if sentinels

          redis = ::Redis.new(redis_options)

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
