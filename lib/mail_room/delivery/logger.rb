require 'logger'

module MailRoom
  module Delivery
    # File/STDOUT Logger Delivery method
    # @author Tony Pitale
    class Logger
      # Build a new delivery, hold the mailbox configuration
      #   open a file or stdout for IO depending on the configuration
      # @param [MailRoom::Mailbox]
      def initialize(mailbox)
        io = File.open(mailbox.log_path, 'a') if mailbox.log_path
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
