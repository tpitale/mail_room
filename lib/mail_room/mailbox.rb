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
      :start_tls => false,
      :delete_after_delivery => false,
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
      when "sidekiq"
        Delivery::Sidekiq
      when "que"
        Delivery::Que
      else
        Delivery::Postback
      end
    end

    # deliver the imap email message
    # @param message [Net::IMAP::FetchData]
    def deliver(message)
      message = message.attr['RFC822']
      return true unless message
      
      delivery_klass.new(parsed_delivery_options).deliver(message)
    end

    # true, false, or ssl options hash
    def ssl_options
      replace_verify_mode(ssl)
    end

    private
    def parsed_delivery_options
      delivery_klass::Options.new(self)
    end

    def replace_verify_mode(options)
      return options unless options.is_a?(Hash)
      return options unless options.has_key?(:verify_mode)

      options[:verify_mode] = case options[:verify_mode]
      when :none, 'none'
        OpenSSL::SSL::VERIFY_NONE
      when :peer, 'peer'
        OpenSSL::SSL::VERIFY_PEER
      when :client_once, 'client_once'
        OpenSSL::SSL::VERIFY_CLIENT_ONCE
      when :fail_if_no_peer_cert, 'fail_if_no_peer_cert'
        OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      end

      options
    end
  end
end
