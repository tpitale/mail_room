require "mail_room/delivery"
require "mail_room/arbitration"

module MailRoom
  # Mailbox Configuration fields
  MAILBOX_FIELDS = [
    :email,
    :password,
    :host,
    :port,
    :ssl,
    :start_tls,
    :search_command,
    :name,
    :delete_after_delivery,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :location, # for letter_opener
    :delivery_options,
    :arbitration_method,
    :arbitration_options
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
      :start_tls => false,
      :delete_after_delivery => false,
      :delivery_options => {},
      :arbitration_method => 'noop',
      :arbitration_options => {}
    }

    # Store the configuration and require the appropriate delivery method
    # @param attributes [Hash] configuration options
    def initialize(attributes={})
      super(*DEFAULTS.merge(attributes).values_at(*members))
    end

    def delivery_klass
      Delivery[delivery_method]
    end

    def arbitration_klass
      Arbitration[arbitration_method]
    end

    def delivery
      @delivery ||= delivery_klass.new(parsed_delivery_options)
    end

    def arbitrator
      @arbitrator ||= arbitration_klass.new(parsed_arbitration_options)
    end

    # deliver the imap email message
    # @param message [Net::IMAP::FetchData]
    def deliver(message)
      body = message.attr['RFC822']
      return true unless body

      return false unless arbitrator.deliver?(message)

      delivery.deliver(body)
    end

    private

    def parsed_arbitration_options
      arbitration_klass::Options.new(self)
    end

    def parsed_delivery_options
      delivery_klass::Options.new(self)
    end
  end
end
