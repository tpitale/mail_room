module MailRoom
  # TODO: split up between processing and idling?

  # Watch a Mailbox
  # @author Tony Pitale
  class MailboxWatcher
    attr_accessor :watching_thread

    # Watch a new mailbox
    # @param mailbox [MailRoom::Mailbox] the mailbox to watch
    def initialize(mailbox)
      @mailbox = mailbox

      @running = false
      @connection = nil
    end

    # are we running?
    # @return [Boolean]
    def running?
      @running
    end

    # run the mailbox watcher
    def run
      MailRoom.structured_logger.info("#{@mailbox.context} Setting up watcher")
      @running = true

      connection.on_new_message do |message|
        @mailbox.deliver(message)
      end

      self.watching_thread = Thread.start do
        while(running?) do
          connection.wait
        end
      end

      watching_thread.abort_on_exception = true
    end

    # stop running, cleanup connection
    def quit
      @running = false

      if @connection
        @connection.quit
        @connection = nil
      end

      if self.watching_thread
        self.watching_thread.join
      end
    end

    private
    def connection
      @connection ||= Connection.new(@mailbox)
    end
  end
end
