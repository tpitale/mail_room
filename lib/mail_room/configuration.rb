require "erb"

module MailRoom
  # Wraps configuration for a set of individual mailboxes with global config
  # @author Tony Pitale
  class Configuration
    attr_accessor :mailboxes, :log_path, :quiet, :health_check

    # Initialize a new configuration of mailboxes
    def initialize(options={})
      self.mailboxes = []
      self.quiet = options.fetch(:quiet, false)

      if options.has_key?(:config_path)
        begin
          erb = ERB.new(File.read(options[:config_path]))
          erb.filename = options[:config_path]
          config_file = YAML.load(erb.result)

          set_mailboxes(config_file[:mailboxes])
          set_health_check(config_file[:health_check])
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

    # Builds the health checker from YAML configuration
    #
    # @param health_check_config nil or a Hash containing :address and :port
    def set_health_check(health_check_config)
      return unless health_check_config

      self.health_check = HealthCheck.new(health_check_config)
    end
  end
end
