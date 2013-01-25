module MailRoom
  class MailboxWatcher
    def initialize(mailbox)
      @mailbox = mailbox

      @running = false
      @logged_in = false
      @idling = false
    end

    def imap
      @imap ||= Net::IMAP.new('imap.gmail.com', :port => 993, :ssl => true)
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

    def stop_idling
    end

    def run
      setup

      @running = true

      @idling_thread = Thread.start do
        while(running?) do
          # block until we stop idling
          idle
          # when new messages are ready
          process_new_messages
        end
      end
    end

    def quit
      @running = false
      stop_idling
    end
  end
end
