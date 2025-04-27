# frozen_string_literal: true

require "mail_room/health_check/nop"
require "mail_room/health_check/http"

# Health checks probe the current health of the process. Default is
# a NOP health check.
module MailRoom
  module HealthCheck
    class Factory
      def self.create(attributes = {})
        case attributes[:type].to_s
        when 'http'
          Http.new(attributes)
        else
          Nop.new(attributes)
        end
      end
    end
  end
end
