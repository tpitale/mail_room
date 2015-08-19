require "redis"
require "securerandom"
require "json"

module MailRoom
  module Delivery
    # Postback Delivery method
    # @author Tony Pitale
    class Sidekiq
      Options = Struct.new(:redis_url, :namespace, :queue, :worker) do
        def initialize(mailbox)
          redis_url = mailbox.delivery_options[:redis_url]
          namespace = mailbox.delivery_options[:namespace]
          queue     = mailbox.delivery_options[:queue]  || "default"
          worker    = mailbox.delivery_options[:worker] || "redis://localhost:6379"

          super(redis_url, namespace, queue, worker)
        end
      end

      attr_accessor :options

      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Mailbox]
      def initialize(options)
        @options = options
      end

      # deliver the message by pushing it onto the configured Sidekiq queue
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        item = item_for(message)

        client.lpush("queue:#{options.queue}", JSON.generate(item))

        true
      end

      private

      def client
        client = Redis.new(url: options.redis_url)

        namespace = options.namespace
        if namespace
          require 'redis/namespace'
          Redis::Namespace.new(namespace, redis: client)
        else
          client
        end
      end

      def item_for(message)
        {
          'class'       => options.worker,
          'args'        => [message],

          'queue'       => options.queue,
          'jid'         => SecureRandom.hex(12),
          'retry'       => false,
          'enqueued_at' => Time.now.to_f
        }
      end
    end
  end
end
