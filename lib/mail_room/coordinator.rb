module MailRoom
  # Coordinate the mailbox watchers
  # @author Tony Pitale
  class Coordinator
    attr_accessor :watchers, :running, :health_check

    # build watchers for a set of mailboxes
    # @params mailboxes [Array<MailRoom::Mailbox>] mailboxes to be watched
    # @params health_check <MailRoom::HealthCheck> health checker to run
    def initialize(mailboxes, health_check = MailRoom::NopHealthCheck.new)
      self.watchers = []

      @health_check = health_check
      mailboxes.each {|box| self.watchers << MailboxWatcher.new(box)}
    end

    alias :running? :running

    # start each of the watchers to running
    def run
      health_check.run
      watchers.each(&:run)

      self.running = true

      sleep_while_running
    ensure
      quit
    end

    # quit each of the watchers when we're done running
    def quit
      health_check.quit
      watchers.each(&:quit)
    end

    private
    # @private
    def sleep_while_running
      # do we need to sweep for dead watchers?
      # or do we let the mailbox rebuild connections
      while(running?) do; sleep 1; end
    end
  end
end
