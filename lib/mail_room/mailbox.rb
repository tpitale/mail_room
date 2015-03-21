module MailRoom
  # Mailbox Configuration fields
  FIELDS = [
    :server,
    :email,
    :password,
    :name,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :location # for letter_opener
  ]

  # Holds configuration for each of the email accounts we wish to monitor
  #   and deliver email to when new emails arrive over imap
  Mailbox = Struct.new(*FIELDS) do
    # Store the configuration and require the appropriate delivery method
    # @param attributes [Hash] configuration options
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

    # deliver the imap email message
    # @param message [Net::IMAP::FetchData]
    def deliver(message)
      delivery_klass.new(self).deliver(message.attr['RFC822'])
    end
  end
end
