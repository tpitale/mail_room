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
    :idle_timeout,
    :search_command,
    :name,
    :delete_after_delivery,
    :expunge_deleted,
    :delivery_klass,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :content_type, # for postback
    :location, # for letter_opener
    :delivery_options,
    :arbitration_method,
    :arbitration_options,
    :logger
  ]

  ConfigurationError = Class.new(RuntimeError)
  IdleTimeoutTooLarge = Class.new(RuntimeError)

  # Holds configuration for each of the email accounts we wish to monitor
  #   and deliver email to when new emails arrive over imap
  Mailbox = Struct.new(*MAILBOX_FIELDS) do
    # Keep it to 29 minutes or less
    # The IMAP serve will close the connection after 30 minutes of inactivity
    # (which sending IDLE and then nothing technically is), so we re-idle every
    # 29 minutes, as suggested by the spec: https://tools.ietf.org/html/rfc2177
    IMAP_IDLE_TIMEOUT = 29 * 60 # 29 minutes in in seconds

    REQUIRED_CONFIGURATION = [:name, :email, :password, :host, :port]

    # Default attributes for the mailbox configuration
    DEFAULTS = {
      :search_command => 'UNSEEN',
      :delivery_method => 'postback',
      :host => 'imap.gmail.com',
      :port => 993,
      :ssl => true,
      :start_tls => false,
      :idle_timeout => IMAP_IDLE_TIMEOUT,
      :delete_after_delivery => false,
      :expunge_deleted => false,
      :delivery_options => {},
      :arbitration_method => 'noop',
      :arbitration_options => {},
      :logger => {}
    }

    # Store the configuration and require the appropriate delivery method
    # @param attributes [Hash] configuration options
    def initialize(attributes={})
      super(*DEFAULTS.merge(attributes).values_at(*members))

      validate!
    end

    def logger
      @logger ||=
        case self[:logger]
          when Logger
            self[:logger]
          else
            self[:logger] ||= {}
            MailRoom::Logger::Structured.new(self[:logger][:log_path])
        end
    end

    def delivery_klass
      self[:delivery_klass] ||= Delivery[delivery_method]
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

    def deliver?(uid)
      logger.info({context: context, uid: uid, action: "asking arbiter to deliver", arbitrator: arbitrator.class.name})

      arbitrator.deliver?(uid)
    end

    # deliver the imap email message
    # @param message [Net::IMAP::FetchData]
    def deliver(message)
      body = message.attr['RFC822']
      return true unless body

      logger.info({context: context, uid: message.attr['UID'], action: "sending to deliverer", deliverer: delivery.class.name, byte_size: message.attr['RFC822.SIZE']})
      delivery.deliver(body)
    end

    # true, false, or ssl options hash
    def ssl_options
      replace_verify_mode(ssl)
    end

    def context
      { email: self.email, name: self.name }
    end

    def validate!
      if self[:idle_timeout] > IMAP_IDLE_TIMEOUT
        raise IdleTimeoutTooLarge,
              "Please use an idle timeout smaller than #{29*60} to prevent " \
              "IMAP server disconnects"
      end

      REQUIRED_CONFIGURATION.each do |k|
        if self[k].nil?
          raise ConfigurationError,
                "Field :#{k} is required in Mailbox: #{inspect}"
        end
      end
    end

    private

    def parsed_arbitration_options
      arbitration_klass::Options.new(self)
    end

    def parsed_delivery_options
      delivery_klass::Options.new(self)
    end

    def replace_verify_mode(options)
      return options unless options.is_a?(Hash)
      return options unless options.has_key?(:verify_mode)

      options[:verify_mode] = lookup_verify_mode(options[:verify_mode])

      options
    end

    def lookup_verify_mode(verify_mode)
      case verify_mode.to_sym
        when :none
          OpenSSL::SSL::VERIFY_NONE
        when :peer
          OpenSSL::SSL::VERIFY_PEER
        when :client_once
          OpenSSL::SSL::VERIFY_CLIENT_ONCE
        when :fail_if_no_peer_cert
          OpenSSL::SSL::VERIFY_FAIL_IF_NO_PEER_CERT
      end
    end
  end
end
