require "redis"

module MailRoom
  module Arbitration
    class Redis
      Options = Struct.new(:redis_url, :namespace, :sentinels, :sentinel_username, :sentinel_password) do
        def initialize(mailbox)
          redis_url = mailbox.arbitration_options[:redis_url] || "redis://localhost:6379"
          namespace = mailbox.arbitration_options[:namespace]
          sentinels = mailbox.arbitration_options[:sentinels]
          sentinel_username = mailbox.arbitration_options[:sentinel_username]
          sentinel_password = mailbox.arbitration_options[:sentinel_password]

          if namespace
            warn <<~MSG
              Redis namespaces are deprecated. This option will be ignored in future versions.
              See https://github.com/sidekiq/sidekiq/issues/2586 for more details."
            MSG
          end

          super(redis_url, namespace, sentinels, sentinel_username, sentinel_password)
        end
      end

      # Expire after 10 minutes so Redis doesn't get filled up with outdated data.
      EXPIRATION = 600

      attr_accessor :options

      def initialize(options)
        @options = options
      end

      def deliver?(uid, expiration = EXPIRATION)
        key = "delivered:#{uid}"

        # Set the key, but only if it doesn't already exist;
        # the return value is true if successful, false if the key was already set,
        # which is conveniently the correct return value for this method
        # Any subsequent failure in the instance which gets the lock will be dealt
        # with by the expiration, at which time another instance can pick up the
        # message and try again.
        client.set(key, 1, nx: true, ex: expiration)
      end

      private

      def client
        @client ||= begin
          sentinels = options.sentinels
          redis_options = { url: options.redis_url }
          redis_options[:sentinels] = sentinels if sentinels
          redis_options[:sentinel_username] = options.sentinel_username if options.sentinel_username
          redis_options[:sentinel_password] = options.sentinel_password if options.sentinel_password

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
