module MailRoom
  module Delivery
    # Noop Delivery method
    # @author Tony Pitale
    class Noop
      # build a new delivery, do nothing
      def initialize(*)
      end

      # accept the delivery, do nothing
      def deliver(*)
      end
    end
  end
end
