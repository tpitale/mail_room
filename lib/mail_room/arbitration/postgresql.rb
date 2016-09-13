require 'pg'

module MailRoom
  module Arbitration
    class PostgreSQL
      Options = Struct.new(:host, :port, :database, :username, :password) do
        def initialize(mailbox)
          host = mailbox.arbitration_options.fetch(:host, "localhost")
          port = mailbox.arbitration_options.fetch(:port, 5432)

          database = mailbox.arbitration_options[:database]
          username = mailbox.arbitration_options[:username]
          password = mailbox.arbitration_options[:password]

          super(host, port, database, username, password)
        end
      end

      attr_reader :options, :connection

      def initialize(options)
        @options = options

        # Retain the PG connection for the life
        # of this mailbox/arbitrator so that locks
        # are not released until the process dies.
        #
        # Hopefully, by that time, all other processes
        # will have already read and passed over
        # delivering the messages that this proccess
        # has already delivered
        @connection = PG.connect({
          host: options.host,
          port: options.port,
          dbname: options.database,
          user: options.username,
          password: options.password
        })
      end

      # Do we deliver this message?
      # 
      # @param uid [Integer] the unique id from mail
      # @return Boolean
      def deliver?(uid)
        obtain_advisory_lock?(uid)
      end

      private

      # @private
      def obtain_advisory_lock?(uid)
        connection.exec_params('SELECT pg_try_advisory_lock($1);', [uid]).getvalue(0,0) == 't'
      end
    end
  end
end
