module MailRoom
  # Wraps configuration for a set of individual mailboxes with global config
  # @author Tony Pitale
  class Configuration
    attr_accessor :mailboxes, :daemonize, :log_path, :pid_path

    # Initialize a new configuration of mailboxes
    def initialize(options={})
      self.mailboxes = []

      if options.has_key?(:config_path)
        config_file = YAML.load_file(options[:config_path])

        set_mailboxes(config_file[:mailboxes])
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
