require 'pg'
require 'json'
require 'charlock_holmes'

module MailRoom
  module Delivery
    # Que Delivery method
    # @author Tony Pitale
    class Que
      Options = Struct.new(:host, :port, :database, :username, :password, :queue, :priority, :job_class, :logger) do
        def initialize(mailbox)
          host = mailbox.delivery_options[:host] || "localhost"
          port = mailbox.delivery_options[:port] || 5432
          database = mailbox.delivery_options[:database]
          username = mailbox.delivery_options[:username]
          password = mailbox.delivery_options[:password]

          queue = mailbox.delivery_options[:queue] || ''
          priority = mailbox.delivery_options[:priority] || 100 # lowest priority for Que
          job_class = mailbox.delivery_options[:job_class]
          logger = mailbox.logger

          super(host, port, database, username, password, queue, priority, job_class, logger)
        end
      end

      attr_reader :options

      # Build a new delivery, hold the mailbox configuration
      # @param [MailRoom::Delivery::Que::Options]
      def initialize(options)
        @options = options
      end

      # deliver the message by pushing it onto the configured Sidekiq queue
      # @param message [String] the email message as a string, RFC822 format
      def deliver(message)
        queue_job(utf8_encode_message(message))
        @options.logger.info({ delivery_method: 'Que', action: 'message pushed' })
      end

      private
      def connection
        PG.connect(connection_options)
      end

      def connection_options
        {
          host: options.host,
          port: options.port,
          dbname: options.database,
          user: options.username,
          password: options.password
        }
      end

      def queue_job(*args)
        sql = "INSERT INTO que_jobs (priority, job_class, queue, args) VALUES ($1, $2, $3, $4)"

        connection.exec(sql, [options.priority, options.job_class, options.queue, JSON.dump(args)])
      end

      def utf8_encode_message(message)
        message = message.dup

        message.force_encoding("UTF-8")
        return message if message.valid_encoding?

        detection = CharlockHolmes::EncodingDetector.detect(message)
        return message unless detection && detection[:encoding]

        # Convert non-UTF-8 body UTF-8 so it can be dumped as JSON.
        CharlockHolmes::Converter.convert(message, detection[:encoding], 'UTF-8')
      end
    end
  end
end
