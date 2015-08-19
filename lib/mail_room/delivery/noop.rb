module MailRoom
  module Delivery
    # Noop Delivery method
    # @author Tony Pitale
    class Noop
      Options = Class.new do
        def initialize(*)
          super()
        end
      end

      # build a new delivery, do nothing
      def initialize(*)
      end

      # accept the delivery, do nothing
      def deliver(*)
        true
      end
    end
  end
end
