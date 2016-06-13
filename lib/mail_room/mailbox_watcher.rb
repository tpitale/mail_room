module MailRoom
  # TODO: split up between processing and idling?

  # Watch a Mailbox
  # @author Tony Pitale
  class MailboxWatcher
    RescuedErrors = [Net::IMAP::Error, IOError,
                     Errno::EPIPE, OpenSSL::SSL::SSLError]

    attr_accessor :idling_thread

    # Watch a new mailbox
    # @param mailbox [MailRoom::Mailbox] the mailbox to watch
    def initialize(mailbox)
      @mailbox = mailbox

      reset
      @running = false
    end

    # build a net/imap connection to google imap
    def imap
      @imap ||= MailRoom::IMAP.new(@mailbox.host, :port => @mailbox.port, :ssl => @mailbox.ssl_options)
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
      start_tls
      log_in
      set_mailbox
    end

    # clear disconnected imap
    # reset imap state
    def reset
      log_out_and_disconnect
      @imap = nil
      @logged_in = false
      @idling = false
    end

    # start a TLS session
    def start_tls
      imap.starttls if @mailbox.start_tls
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
    # block for idle_timeout until we stop idling
    def idle
      return unless ready_to_idle?

      @idling = true

      protected_call do
        imap.idle(@mailbox.idle_timeout, &idle_handler)
      end
    ensure
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

      self.idling_thread = Thread.start do
        while(running?) do
          idle if process_mailbox
        end
        reset
      end

      idling_thread.abort_on_exception = true
    end

    # stop running
    def quit
      @running = false
      stop_idling
    end

    def log_out_and_disconnect
      return unless @imap

      @imap.logout
      @imap.disconnect
    rescue *RescuedErrors => e
      warn "#{Time.now} #{e.class}: #{e.inspect} in #{caller.take(10)}"
    end

    # when new messages are ready
    # trigger the handler to process this mailbox for new messages
    def process_mailbox
      protected_call do
        handler.process
      end
    end

    private
    # @private
    def idle_handler
      lambda {|response| imap.idle_done if message_exists?(response)}
    end

    def protected_call
      yield
      true
    rescue *RescuedErrors => e
      warn "#{Time.now} #{e.class}: #{e.inspect} in #{caller.take(10)}"
      # we've been disconnected, so re-setup
      setup
      false
    end
  end
end
