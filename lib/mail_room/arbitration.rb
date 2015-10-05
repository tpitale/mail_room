module MailRoom
  module Arbitration
    def self.[](name)
      require_relative("./arbitration/#{name}")

      case name
      when "redis"
        Arbitration::Redis
      else
        Arbitration::Noop
      end
    end
  end
end
