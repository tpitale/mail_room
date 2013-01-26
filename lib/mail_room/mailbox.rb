module MailRoom
  Mailbox = Struct.new(*[
    :email,
    :password,
    :name,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :location # for letter_opener
  ])

  class Mailbox
    def initialize(attributes={})
      super(*attributes.values_at(*members))

      require_relative("./delivery/#{(delivery_method || 'postback')}")
    end

    # move to a mailbox deliverer class?
    def delivery_klass
      case delivery_method
      when "noop"
        Delivery::Noop
      when "logger"
        Delivery::Logger
      when "letter_opener"
        Delivery::LetterOpener
      else
        Delivery::Postback
      end
    end

    def deliver(message)
      delivery_klass.new(self).deliver(message.attr['RFC822'])
    end
  end
end
