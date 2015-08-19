module MailRoom
  # Mailbox Configuration fields
  MAILBOX_FIELDS = [
    :email,
    :password,
    :host,
    :port,
    :ssl,
    :search_command,
    :name,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :location, # for letter_opener
    :delivery_options
  ]

  # Holds configuration for each of the email accounts we wish to monitor
  #   and deliver email to when new emails arrive over imap
  Mailbox = Struct.new(*MAILBOX_FIELDS) do
    # Default attributes for the mailbox configuration
    DEFAULTS = {
      :search_command => 'UNSEEN',
      :delivery_method => 'postback',
      :host => 'imap.gmail.com',
      :port => 993,
      :ssl => true,
      :delivery_options => {}
    }

    # Store the configuration and require the appropriate delivery method
    # @param attributes [Hash] configuration options
    def initialize(attributes={})
      super(*DEFAULTS.merge(attributes).values_at(*members))

      require_relative("./delivery/#{(delivery_method)}")
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
      delivery_klass.new(parsed_delivery_options).deliver(message.attr['RFC822'])
    end

    private
    def parsed_delivery_options
      delivery_klass::Options.new(self)
    end
  end
end
