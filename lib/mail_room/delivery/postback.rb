require 'faraday'
require "mail_room/jwt"

module MailRoom
  module Delivery
    # Postback Delivery method
    # @author Tony Pitale
    class Postback
      Options = Struct.new(:url, :token, :username, :password, :logger, :content_type, :jwt) do
        def initialize(mailbox)
          url =
            mailbox.delivery_url ||
            mailbox.delivery_options[:delivery_url] ||
            mailbox.delivery_options[:url]

          token =
            mailbox.delivery_token ||
            mailbox.delivery_options[:delivery_token] ||
            mailbox.delivery_options[:token]

          jwt = initialize_jwt(mailbox.delivery_options)

          username = 
            mailbox.delivery_options[:username] ||
            mailbox.delivery_options[:delivery_username]
          password = 
            mailbox.delivery_options[:password] ||
            mailbox.delivery_options[:delivery_password] ||
            ENV['delivery_password']

          logger = mailbox.logger

          content_type = mailbox.delivery_options[:content_type]

          super(url, token, username, password, logger, content_type, jwt)
        end

        def token_auth?
          !self[:token].nil?
        end

        def jwt_auth?
          self[:jwt].valid?
        end

        def basic_auth?
          !self[:username].nil? && !self[:password].nil?
        end

        private

        def initialize_jwt(delivery_options)
          ::MailRoom::JWT.new(
            header: delivery_options[:jwt_auth_header],
            secret_path: delivery_options[:jwt_secret_path],
            algorithm: delivery_options[:jwt_algorithm],
            issuer: delivery_options[:jwt_issuer]
          )
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
          config_request_content_type(request)
          config_request_jwt_auth(request)
        end

        @delivery_options.logger.info({ delivery_method: 'Postback', action: 'message pushed', url: @delivery_options.url })
        true
      end

      private

      def config_request_content_type(request)
        return if @delivery_options.content_type.nil?

        request.headers['Content-Type'] = @delivery_options.content_type
      end

      def config_request_jwt_auth(request)
        return unless @delivery_options.jwt_auth?

        request.headers[@delivery_options.jwt.header] = @delivery_options.jwt.token
      end
    end
  end
end
