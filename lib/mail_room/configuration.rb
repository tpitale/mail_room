module MailRoom
  class Configuration
    attr_accessor :mailboxes, :daemonize, :log_path, :pid_path

    def initialize(options={})
      self.mailboxes = []

      if options.has_key?(:config_path)
        config_file = YAML.load_file(options[:config_path])

        load_mailboxes(config_file[:mailboxes])
      end
    end

    def load_mailboxes(mailboxes_config)
      mailboxes_config.each do |attributes|
        self.mailboxes << Mailbox.new(attributes)
      end
    end

    alias :daemonize? :daemonize
  end
end
