module MailRoom
  module Connection
    class Base
      attr_accessor :mailbox

      def initialize(mailbox)
        @mailbox = mailbox
      end

      def on_new_message(&block)
        raise NotImplementedError
      end

      def quit
        raise NotImplementedError
      end
    end
  end
end
