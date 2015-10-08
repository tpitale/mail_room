module MailRoom
  module Arbitration
    def [](name)
      require_relative("./arbitration/#{name}")

      case name
      when "redis"
        Arbitration::Redis
      else
        Arbitration::Noop
      end
    end

    module_function :[]
  end
end
