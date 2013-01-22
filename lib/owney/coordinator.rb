module Owney
  class Coordinator
    attr_accessor :handlers

    def initialize(mailboxes)
      self.handlers = []

      mailboxes.each {|mb| self.handlers << MessageHandler.new(mb)}
    end

    def run
      handlers.each(&:run!)
    end

    def quit
      handlers.each(&:quit!)
    end
  end
end
