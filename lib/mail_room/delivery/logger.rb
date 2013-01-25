module MailRoom
  module Delivery
    class Logger
      def initialize(mailbox)
        io = File.open(mailbox.log_path) if mailbox.log_path
        io ||= STDOUT

        io.sync = true

        @logger = Logger.new(io)
      end

      def deliver!(message)
        @logger.info message
      end
    end
  end
end
