require 'mail'
require 'letter_opener'

module MailRoom
  module Delivery
    class LetterOpener
      def initialize(mailbox)
        @mailbox = mailbox
      end

      def deliver!(message)
        method = LetterOpener::DeliveryMethod.new(:location => @mailbox.location)
        method.deliver!(Mail.read_from_string(message))
      end
    end
  end
end
