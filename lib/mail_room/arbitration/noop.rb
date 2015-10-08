module MailRoom
  module Arbitration
    class Noop
      Options = Class.new do
        def initialize(*)
          super()
        end
      end

      def initialize(*)
      end

      def deliver?(*)
        true
      end
    end
  end
end
