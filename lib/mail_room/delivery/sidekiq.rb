require "redis"
require "securerandom"
require "json"
require "charlock_holmes"

module MailRoom
  module Delivery
    # Sidekiq Delivery method
    # @author Douwe Maan
    class Sidekiq
      Options = Struct.new(:redis_url, :namespace, :sentinels, :queue, :worker, :logger, :redis_db, :sentinel_username, :sentinel_password) do
        def initialize(mailbox)
          redis_url = mailbox.delivery_options[:redis_url] || "redis://localhost:6379"
          redis_db  = mailbox.delivery_options[:redis_db] || 0
          namespace = mailbox.delivery_options[:namespace]
          sentinels = mailbox.delivery_options[:sentinels]
          sentinel_username = mailbox.delivery_options[:sentinel_username]
          sentinel_password = mailbox.delivery_options[:sentinel_password]
          queue     = mailbox.delivery_options[:queue] || "default"
          worker    = mailbox.delivery_options[:worker]
          logger = mailbox.logger

          if namespace
            warn <<~MSG
              Redis namespaces are deprecated. This option will be ignored in future versions.
              See https://github.com/sidekiq/sidekiq/issues/2586 for more details."
            MSG
          end

          super(redis_url, namespace, sentinels, queue, worker, logger, redis_db, sentinel_username, sentinel_password)
        end
      end

      attr_accessor :options

      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Delivery::Sidekiq::Options]
      def initialize(options)
        @options = options
      end

      # deliver the message by pushing it onto the configured Sidekiq queue
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        item = item_for(message)

        client.lpush("queue:#{options.queue}", JSON.generate(item))

        @options.logger.info({ delivery_method: 'Sidekiq', action: 'message pushed' })
        true
      end

      private

      def client
        @client ||= begin
          sentinels = options.sentinels
          redis_options = { url: options.redis_url, db: options.redis_db }
          redis_options[:sentinels] = sentinels if sentinels
          redis_options[:sentinel_username] = options.sentinel_username if options.sentinel_username
          redis_options[:sentinel_password] = options.sentinel_password if options.sentinel_password

          redis = ::Redis.new(redis_options)

          namespace = options.namespace
          if namespace
            require 'redis/namespace'
            Redis::Namespace.new(namespace, redis: redis)
          else
            redis
          end
        end
      end

      def item_for(message)
        {
          'class'       => options.worker,
          'args'        => [utf8_encode_message(message)],
          'queue'       => options.queue,
          'jid'         => SecureRandom.hex(12),
          'retry'       => false,
          'enqueued_at' => Time.now.to_f
        }
      end

      def utf8_encode_message(message)
        message = message.dup

        message.force_encoding("UTF-8")
        return message if message.valid_encoding?

        detection = CharlockHolmes::EncodingDetector.detect(message)
        return message unless detection && detection[:encoding]

        # Convert non-UTF-8 body UTF-8 so it can be dumped as JSON.
        CharlockHolmes::Converter.convert(message, detection[:encoding], 'UTF-8')
      end
    end
  end
end
