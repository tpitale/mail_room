module MailRoom
  # TODO: split up between processing and idling?

  # Watch a Mailbox
  # @author Tony Pitale
  class MailboxWatcher
    attr_accessor :idling_thread, :timeout_thread

    # Watch a new mailbox
    # @param mailbox [MailRoom::Mailbox] the mailbox to watch
    def initialize(mailbox)
      @mailbox = mailbox

      reset
      @running = false
    end

    # build a net/imap connection to google imap
    def imap
      @imap ||= Net::IMAP.new(@mailbox.host, :port => @mailbox.port, :ssl => @mailbox.ssl)
    end

    # build a handler to process mailbox messages
    def handler
      @handler ||= MailboxHandler.new(@mailbox, imap)
    end

    # are we running?
    # @return [Boolean]
    def running?
      @running
    end

    # is the connection logged in?
    # @return [Boolean]
    def logged_in?
      @logged_in
    end

    # is the connection blocked idling?
    # @return [Boolean]
    def idling?
      @idling
    end

    # is the imap connection closed?
    # @return [Boolean]
    def disconnected?
      @imap.disconnected?
    end

    # is the connection ready to idle?
    # @return [Boolean]
    def ready_to_idle?
      logged_in? && !idling?
    end

    # is the response for a new message?
    # @param response [Net::IMAP::TaggedResponse] the imap response from idle
    # @return [Boolean]
    def message_exists?(response)
      response.respond_to?(:name) && response.name == 'EXISTS'
    end

    # log in and set the mailbox
    def setup
      reset
      log_in
      set_mailbox
    end

    # clear disconnected imap
    # reset imap state
    def reset
      @imap = nil
      @logged_in = false
      @idling = false
    end

    # send the imap login command to google
    def log_in
      imap.login(@mailbox.email, @mailbox.password)
      @logged_in = true
    end

    # select the mailbox name we want to use
    def set_mailbox
      imap.select(@mailbox.name) if logged_in?
    end

    # maintain an imap idle connection
    def idle
      return unless ready_to_idle?

      @idling = true

      self.timeout_thread = Thread.start do
        # The IMAP server will close the connection after 30 minutes, so re-idle
        # every 29 minutes, as suggested by the spec: https://tools.ietf.org/html/rfc2177
        sleep 29 * 60

        imap.idle_done if idling?
      end
      timeout_thread.abort_on_exception = true

      imap.idle(&idle_handler)
    ensure
      timeout_thread.kill if timeout_thread
      self.timeout_thread = nil
      @idling = false
    end

    # trigger the idle to finish and wait for the thread to finish
    def stop_idling
      return unless idling?

      imap.idle_done
      
      idling_thread.join
      self.idling_thread = nil
    end

    # run the mailbox watcher
    def run
      setup

      @running = true

      # prefetch messages before first idle
      process_mailbox

      self.idling_thread = Thread.start do
        while(running?) do
          begin
            # block until we stop idling
            idle

            # when new messages are ready
            process_mailbox
          rescue Net::IMAP::Error, IOError => e
            # we've been disconnected, so re-setup
            setup
          end
        end
      end

      idling_thread.abort_on_exception = true
    end

    # stop running
    def quit
      @running = false
      stop_idling
      # disconnect
    end

    # trigger the handler to process this mailbox for new messages
    def process_mailbox
      handler.process
    end

    private
    # @private
    def idle_handler
      lambda {|response| imap.idle_done if message_exists?(response)}
    end
  end
end
