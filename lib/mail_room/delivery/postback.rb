require 'faraday'

module MailRoom
  module Delivery
    # Postback Delivery method
    # @author Tony Pitale
    class Postback
      Options = Struct.new(:url, :token, :username, :password, :logger, :content_type) do
        def initialize(mailbox)
          url =
            mailbox.delivery_url ||
            mailbox.delivery_options[:delivery_url] ||
            mailbox.delivery_options[:url]

          token =
            mailbox.delivery_token ||
            mailbox.delivery_options[:delivery_token] ||
            mailbox.delivery_options[:token]

          username = mailbox.delivery_options[:username]
          password = mailbox.delivery_options[:password]

          logger = mailbox.logger

          content_type = mailbox.delivery_options[:content_type]

          super(url, token, username, password, logger, content_type)
        end

        def token_auth?
          !self[:token].nil?
        end

        def basic_auth?
          !self[:username].nil? && !self[:password].nil?
        end
      end

      # Build a new delivery, hold the delivery options
      # @param [MailRoom::Delivery::Postback::Options]
      def initialize(delivery_options)
        puts delivery_options
        @delivery_options = delivery_options
      end

      # deliver the message using Faraday to the configured delivery_options url
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        connection = Faraday.new

        if @delivery_options.token_auth?
          connection.token_auth @delivery_options.token
        elsif @delivery_options.basic_auth?
          connection.basic_auth(
            @delivery_options.username,
            @delivery_options.password
          )
        end

        connection.post do |request|
          request.url @delivery_options.url
          request.body = message
          # request.options[:timeout] = 3
          request.headers['Content-Type'] = @delivery_options.content_type unless @delivery_options.content_type.nil?
        end

        @delivery_options.logger.info({ delivery_method: 'Postback', action: 'message pushed', url: @delivery_options.url })
        true
      end
    end
  end
end
