require 'faraday'

module MailRoom
  module Delivery
    # Postback Delivery method
    # @author Tony Pitale
    class Postback
      Options = Struct.new(:delivery_url, :delivery_token) do
        def initialize(mailbox)
          delivery_url = mailbox.delivery_url || mailbox.delivery_options[:delivery_url]
          delivery_token = mailbox.delivery_token || mailbox.delivery_options[:delivery_token]

          super(delivery_url, delivery_token)
        end
      end

      # Build a new delivery, hold the delivery options
      # @param [MailRoom::Delivery::Postback::Options]
      def initialize(delivery_options)
        @delivery_options = delivery_options
      end

      # deliver the message using Faraday to the configured delivery_options url
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        connection = Faraday.new
        connection.token_auth @delivery_options.delivery_token

        connection.post do |request|
          request.url @delivery_options.delivery_url
          request.body = message
          # request.options[:timeout] = 3
          # request.headers['Content-Type'] = 'text/plain'
        end

        MailRoom.structured_logger.info("Message delivered to #{@delivery_options.delivery_url}")
        true
      end
    end
  end
end
