module MailRoom
  module Delivery
    class Noop
      def initialize(*)
      end

      def deliver(*)
      end
    end
  end
end
