module MailRoom
  # split up between processing and idling?
  class MailboxWatcher
    attr_accessor :idling_thread

    def initialize(mailbox)
      @mailbox = mailbox

      @running = false
      @logged_in = false
      @idling = false
    end

    def imap
      @imap ||= Net::IMAP.new('imap.gmail.com', :port => 993, :ssl => true)
    end

    def handler
      @handler ||= MailboxHandler.new(@mailbox, imap)
    end

    def running?
      @running
    end

    def logged_in?
      @logged_in
    end

    def idling?
      @idling
    end

    def setup
      log_in
      set_mailbox
    end

    def log_in
      imap.login(@mailbox.email, @mailbox.password)
      @logged_in = true
    end

    def set_mailbox
      imap.select(@mailbox.name) if logged_in?
    end

    def idle
      return unless logged_in?

      @idling = true

      imap.idle do |response|
        if response.respond_to?(:name) && response.name == 'EXISTS'
          imap.idle_done
        end
      end

      @idling = false
    end

    def process_mailbox
      handler.process
    end

    def stop_idling
      return unless idling?

      imap.idle_done
      idling_thread.join
    end

    def run
      setup

      @running = true

      self.idling_thread = Thread.start do
        while(running?) do
          # block until we stop idling
          idle
          # when new messages are ready
          process_mailbox
        end
      end
    end

    def quit
      @running = false
      stop_idling
    end
  end
end
