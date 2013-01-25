module MailRoom
  class CLI
    attr_accessor :configuration

    def initialize(args)
      options = {}

      OptionParser.new do |parser|
        parser.banner = [
          "Usage: #{@name} [-c config_file]\n",
          "       #{@name} --help\n"
        ].compact.join

        parser.on('-c', '--config FILE') do |path|
          options[:config_path] = path
        end

        # parser.on("-l", "--log FILE") do |path|
        #   options[:log_path] = path
        # end

        parser.on_tail("-?", "--help", "Display this usage information.") do
          puts "#{parser}\n"
          exit
        end
      end.parse!(args)

      self.configuration = Configuration.new(options)
    end

    def run
      start
    end

    def running?
      @running
    end

    def start
      @running = true

      @coordinator ||= Coordinator.new(configuration.mailboxes)
      @coordinator.run

      Signal.trap(:INT) do
        stop
      end

      Signal.trap(:TERM) do
        exit
      end

      while(running?) do; sleep 1; end
    end

    def stop
      return unless @coordinator

      @coordinator.quit

      @running = false
    end
  end
end
