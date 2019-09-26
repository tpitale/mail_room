require 'logger'
require 'json'

module MailRoom
  module Logger
    class Structured < ::Logger

      def format_message(severity, timestamp, progname, message)
        raise ArgumentError.new("Message must be a Hash") unless message.is_a? Hash

        data = {}
        data[:severity] = severity
        data[:time] = timestamp || Time.now.to_s
        # only accept a Hash
        data.merge!(message)

        data.to_json + "\n"
      end
    end
  end
end
