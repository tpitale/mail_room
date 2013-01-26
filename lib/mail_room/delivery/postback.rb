require 'faraday'

module MailRoom
  module Delivery
    class Postback
      def initialize(mailbox)
        @mailbox = mailbox
      end

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
