module MailRoom
  # The CLI parses ARGV into configuration to start the coordinator with.
  # @author Tony Pitale
  class CLI
    attr_accessor :configuration, :coordinator, :options

    # Initialize a new CLI instance to handle option parsing from arguments
    #   into configuration to start the coordinator running on all mailboxes
    #
    # @param args [Array] `ARGV` passed from `bin/mail_room`
    def initialize(args)
      @options = {}

      OptionParser.new do |parser|
        parser.banner = [
          "Usage: #{@name} [-c config_file]\n",
          "       #{@name} --help\n"
        ].compact.join

        parser.on('-c', '--config FILE') do |path|
          options[:config_path] = path
        end

        parser.on('-q', '--quiet') do
          options[:quiet] = true
        end

        parser.on('--log-exit-as') do |format|
          options[:exit_error_format] = 'json' unless format.nil?
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
      self.coordinator = Coordinator.new(configuration.mailboxes, configuration.health_check)
    end

    # Start the coordinator running, sets up signal traps
    def start
      Signal.trap(:INT) do
        coordinator.running = false
      end

      Signal.trap(:TERM) do
        exit
      end

      coordinator.run
    rescue Exception => e # not just Errors, but includes lower-level Exceptions
      CrashHandler.new.handle(e, @options[:exit_error_format])
      exit
    end
  end
end
