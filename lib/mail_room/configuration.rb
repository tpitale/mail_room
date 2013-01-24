module MailRoom
  class Configuration
    attr_accessor :mailboxes, :daemonize, :log_path, :pid_path

    def initialize(options={})
      config_file = YAML.load_file(options[:config_path]) if options.has_key?(:config_path)

      self.mailboxes = []
      load_mailboxes(config_file[:mailboxes])

      self.daemonize = options.fetch(:daemonize, false)
      self.log_path = options.fetch(:log_path, nil)
      self.pid_path = options.fetch(:pid_path, "/var/run/mail_room.pid")
    end

    def load_mailboxes(mailboxes_config)
      mailboxes_config.each do |attributes|
        self.mailboxes << Mailbox.new(attributes)
      end
    end

    alias :daemonize? :daemonize
  end
end
