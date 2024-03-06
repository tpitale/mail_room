# frozen_string_literal: true

module MailRoom
  module HealthCheck
    class Http
      attr_reader :address, :port, :running

      def initialize(attributes = {})
        @address = attributes[:address]
        @port = attributes[:port]

        validate!
      end

      def run
        @server = create_server

        @thread = Thread.new do
          @server.start
        end

        @thread.abort_on_exception = true
        @running = true
      end

      def quit
        @running = false
        @server&.shutdown
        @thread&.join(60)
      end

      def validate!
        raise 'No health check address specified' unless address
        raise "Health check port #{@port.to_i} is invalid" unless port.to_i.positive?
      end

      private

      def create_server
        require 'webrick'

        server = ::WEBrick::HTTPServer.new(Port: port, BindAddress: address, AccessLog: [])

        server.mount_proc '/liveness' do |_req, res|
          handle_liveness(res)
        end

        server
      end

      def handle_liveness(res)
        if @running
          res.status = 200
          res.body = "OK\n"
        else
          res.status = 500
          res.body = "Not running\n"
        end
      end
    end
  end
end
