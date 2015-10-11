require "erb"

module MailRoom
  # Wraps configuration for a set of individual mailboxes with global config
  # @author Tony Pitale
  class Configuration
    attr_accessor :mailboxes, :daemonize, :log_path, :pid_path, :quiet

    # Initialize a new configuration of mailboxes
    def initialize(options={})
      self.mailboxes = []
      self.quiet = options.fetch(:quiet, false)

      if options.has_key?(:config_path)
        begin
          config_file = YAML.load(ERB.new(File.read(options[:config_path])).result)

          set_mailboxes(config_file[:mailboxes])
        rescue => e
          raise e unless quiet
        end
      end
    end

    # Builds individual mailboxes from YAML configuration
    # 
    # @param mailboxes_config
    def set_mailboxes(mailboxes_config)
      mailboxes_config.each do |attributes|
        self.mailboxes << Mailbox.new(attributes)
      end
    end
  end
end
