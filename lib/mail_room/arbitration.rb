module MailRoom
  module Arbitration
    def [](name = nil)
      require_relative("./arbitration/#{name}") if name

      case name
      when "redis"
        Arbitration::Redis
      when "postgresql"
        Arbitration::PostgreSQL
      else
        Arbitration::Noop
      end
    end

    module_function :[]
  end
end
