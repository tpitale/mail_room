require 'erb'

module MailRoom
  class Configuration
    attr_accessor :mailboxes, :daemonize, :log_path, :pid_path

    def initialize(options={})
      self.mailboxes = []

      if options.has_key?(:config_path)
        config_file = YAML.load(ERB.new(File.new(options[:config_path]).read).result)
        set_mailboxes(config_file[:mailboxes])
      end
    end

    def set_mailboxes(mailboxes_config)
      mailboxes_config.each do |attributes|
        self.mailboxes << Mailbox.new(attributes)
      end
    end
  end
end
