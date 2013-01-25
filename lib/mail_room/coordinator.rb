module MailRoom
  class Coordinator
    attr_accessor :watchers, :running

    def initialize(mailboxes)
      self.watchers = []

      mailboxes.each {|box| self.watchers << MailboxWatcher.new(box)}
    end

    alias :running? :running

    def run
      watchers.each(&:run)

      self.running = true

      while(running?) do; sleep 1; end
    end

    def quit
      watchers.each(&:quit)

      self.running = false
    end
  end
end
