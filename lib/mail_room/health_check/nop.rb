# frozen_string_literal: true

module MailRoom
  class NopHealthCheck < HealthCheck
    def initialize(attributes = {}); end

    def run; end

    def validate!; end
  end
end
