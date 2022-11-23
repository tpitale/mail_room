require 'date'
require 'logger'
require 'json'

module MailRoom
  module Logger
    class Structured < ::Logger

      def format_message(severity, timestamp, progname, message)
        raise ArgumentError.new("Message must be a Hash") unless message.is_a? Hash

        data = {}
        data[:severity] = severity
        data[:time] = format_timestamp(timestamp || Time.now)
        # only accept a Hash
        data.merge!(message)

        data.to_json + "\n"
      end

      private

      def format_timestamp(timestamp)
        case timestamp
        when Time
          timestamp.to_datetime.iso8601(3).to_s
        when DateTime
          timestamp.iso8601(3).to_s
        else
          timestamp
        end
      end
    end
  end
end
