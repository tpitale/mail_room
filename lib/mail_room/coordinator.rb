module MailRoom
  class Coordinator
    attr_accessor :handlers, :running

    def initialize(mailboxes)
      self.handlers = []

      mailboxes.each {|mb| self.handlers << MessageHandler.new(mb)}
    end

    alias :running? :running

    def run
      handlers.each(&:run)

      self.running = true

      while(running?) do; sleep 1; end
    end

    def quit
      handlers.each(&:quit)

      self.running = false
    end
  end
end
