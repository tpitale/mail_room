module Owney
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

        parser.on("-d", "--daemon", "Daemonize mode") do |v|
          options[:daemonize] = v
        end

        parser.on("-l", "--log FILE") do |path|
          options[:log_path] = path
        end

        parser.on("-p", "--pid FILE") do |path|
          options[:pid_path] = path
        end

        parser.on_tail("-?", "--help", "Display this usage information.") do
          puts "#{parser}\n"
          exit
        end
      end.parse!(args)

      self.configuration = Configuration.new(options)
    end

    def run
      if configuration.daemonize?
        daemonize
      else
        start
      end
    end

    def running?
      @running
    end

    def daemonize
      exit if fork
      Process.setsid
      exit if fork
      store_pid(Process.pid)
      File.umask 0000
      redirect_output!

      start

      clean_pid
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

    def store_pid(pid)
      pid_path = configuration.pid_path

      puts pid_path

      FileUtils.mkdir_p(File.dirname(pid_path))
      File.open(pid_path, 'w'){|f| f.write("#{pid}\n")}
    end

    def clean_pid
      pid_path = configuration.pid_path

      begin
        FileUtils.rm pid_path if File.exists?(pid_path)
      rescue => e
      end
    end


    def redirect_output!
      if log_path = configuration.log_path
        # if the log directory doesn't exist, create it
        FileUtils.mkdir_p File.dirname(log_path), :mode => 0755
        # touch the log file to create it
        FileUtils.touch log_path
        # Set permissions on the log file
        File.chmod(0644, log_path)
        # Reopen $stdout (NOT +STDOUT+) to start writing to the log file
        $stdout.reopen(log_path, 'a')
        # Redirect $stderr to $stdout
        $stderr.reopen $stdout
        $stdout.sync = true
      else # redirect to /dev/null
        # We're not bothering to sync if we're dumping to /dev/null
        # because /dev/null doesn't care about buffered output
        $stdin.reopen '/dev/null'
        $stdout.reopen '/dev/null', 'a'
        $stderr.reopen $stdout
      end
    end
  end
end
