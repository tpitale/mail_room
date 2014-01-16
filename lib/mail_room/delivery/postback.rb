require 'faraday'

module MailRoom
  module Delivery
    # Postback Delivery method
    # @author Tony Pitale
    class Postback
      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Mailbox]
      def initialize(mailbox)
        @mailbox = mailbox
      end

      # deliver the message using Faraday to the configured mailbox url
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        connection = Faraday.new
        connection.token_auth @mailbox.delivery_token

        connection.post do |request|
          request.url @mailbox.delivery_url
          request.body = message
          # request.options[:timeout] = 3
          # request.headers['Content-Type'] = 'text/plain'
        end
      end
    end
  end
end
