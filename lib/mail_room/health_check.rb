# frozen_string_literal: true

# Health checks probe the current health of the process.
module MailRoom
  class HealthCheck
    def self.create(attributes = {})
      case attributes[:type].to_s
      when 'http'
        HttpHealthCheck.new(attributes)
      else
        NopHealthCheck.new(attributes)
      end
    end

    def initialize(attributes = {}); end

    def run
      raise NotImplementedError
    end

    def validate!
      raise NotImplementedError
    end

    def quit; end
  end
end

require "mail_room/health_check/nop"
require "mail_room/health_check/http"
