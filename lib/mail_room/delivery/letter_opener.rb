require 'erb'
require 'mail'
require 'letter_opener'

module MailRoom
  module Delivery
    # LetterOpener Delivery method
    # @author Tony Pitale
    class LetterOpener
      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Mailbox]
      def initialize(mailbox)
        @mailbox = mailbox
      end

      # Trigger `LetterOpener` to deliver our message
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        method = ::LetterOpener::DeliveryMethod.new(:location => @mailbox.location)
        method.deliver!(Mail.read_from_string(message))
      end
    end
  end
end
