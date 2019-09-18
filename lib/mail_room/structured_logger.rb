require 'logger'
require 'json'

module MailRoom
  class StructuredLogger < Logger

    def format_message(severity, timestamp, progname, message)
      data = {}
      data[:severity] = severity
      data[:time] = timestamp || Time.now.to_s

      if message.is_a? String
        data[:message] = message
      elsif message.is_a? Hash
        data.merge!(message)
      end

      data.to_json + "\n"
    end
  end
end
