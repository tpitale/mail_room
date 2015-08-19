require 'erb'
require 'mail'
require 'letter_opener'

module MailRoom
  module Delivery
    # LetterOpener Delivery method
    # @author Tony Pitale
    class LetterOpener
      Options = Struct.new(:location) do
        def initialize(mailbox)
          location = mailbox.location || mailbox.delivery_options[:location]

          super(location)
        end
      end

      # Build a new delivery, hold the delivery options
      # @param [MailRoom::Delivery::LetterOpener::Options]
      def initialize(delivery_options)
        @delivery_options = delivery_options
      end

      # Trigger `LetterOpener` to deliver our message
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        method = ::LetterOpener::DeliveryMethod.new(:location => @delivery_options.location)
        method.deliver!(Mail.read_from_string(message))
      end
    end
  end
end
