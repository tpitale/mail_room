module MailRoom
  # Coordinate the mailbox watchers
  # @author Tony Pitale
  class Coordinator
    attr_accessor :watchers, :running

    # build watchers for a set of mailboxes
    # @params mailboxes [Array<MailRoom::Mailbox>] mailboxes to be watched
    def initialize(mailboxes)
      self.watchers = []

      mailboxes.each {|box| self.watchers << MailboxWatcher.new(box)}
    end

    alias :running? :running

    # start each of the watchers to running
    def run
      watchers.each(&:run)
      
      self.running = !watchers.empty?
      
      sleep_while_running
    ensure
      quit
    end

    # quit each of the watchers when we're done running
    def quit
      watchers.each(&:quit)
    end

    private
    # @private
    def sleep_while_running
      while(running?) do; sleep 1; end
    end
  end
end
