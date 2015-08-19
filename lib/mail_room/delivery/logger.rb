require 'logger'

module MailRoom
  module Delivery
    # File/STDOUT Logger Delivery method
    # @author Tony Pitale
    class Logger
      Options = Struct.new(:log_path) do
        def initialize(mailbox)
          log_path = mailbox.log_path || mailbox.delivery_options[:log_path]

          super(log_path)
        end
      end

      # Build a new delivery, hold the delivery options
      #   open a file or stdout for IO depending on the options
      # @param [MailRoom::Delivery::Logger::Options]
      def initialize(delivery_options)
        io = File.open(delivery_options.log_path, 'a') if delivery_options.log_path
        io ||= STDOUT

        io.sync = true

        @logger = ::Logger.new(io)
      end

      # Write the message to our logger
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        @logger.info message
      end
    end
  end
end
