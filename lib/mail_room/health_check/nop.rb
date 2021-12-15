# frozen_string_literal: true

module MailRoom
  module HealthCheck
    class Nop
      def initialize(attributes = {}); end

      def quit; end

      def run; end

      def validate!; end
    end
  end
end
