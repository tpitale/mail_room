module MailRoom
  module Delivery
    def self.[](name)
      require_relative("./delivery/#{name}")

      case name
      when "postback"
        Delivery::Postback
      when "logger"
        Delivery::Logger
      when "letter_opener"
        Delivery::LetterOpener
      when "sidekiq"
        Delivery::Sidekiq
      when "que"
        Delivery::Que
      else
        Delivery::Noop
      end
    end
  end
end
