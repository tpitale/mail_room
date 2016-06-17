module MailRoom
  class Connection
    def initialize(mailbox)
      @mailbox = mailbox

      # log in and set the mailbox
      reset
      setup
    end

    def on_new_message(&block)
      @new_message_handler = block
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

    def quit
      stop_idling
      reset
    end

    def wait
      begin
        # in case we missed any between idles
        process_mailbox

        idle

        process_mailbox
      rescue Net::IMAP::Error, IOError
        reset
        setup
      end
    end

    private

    def reset
      @imap = nil
      @logged_in = false
      @idling = false
    end

    def setup
      start_tls
      log_in
      set_mailbox
    end

    # build a net/imap connection to google imap
    def imap
      @imap ||= MailRoom::IMAP.new(@mailbox.host, :port => @mailbox.port, :ssl => @mailbox.ssl_options)
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

    # is the response for a new message?
    # @param response [Net::IMAP::TaggedResponse] the imap response from idle
    # @return [Boolean]
    def message_exists?(response)
      response.respond_to?(:name) && response.name == 'EXISTS'
    end

    # @private
    def idle_handler
      lambda {|response| imap.idle_done if message_exists?(response)}
    end

    # maintain an imap idle connection
    def idle
      return unless ready_to_idle?

      @idling = true

      imap.idle(@mailbox.idle_timeout, &idle_handler)
    ensure
      @idling = false
    end

    # trigger the idle to finish and wait for the thread to finish
    def stop_idling
      return unless idling?

      imap.idle_done
      
      # idling_thread.join
      # self.idling_thread = nil
    end

    def process_mailbox
      return unless @new_message_handler

      new_messages.map do |message|
        [@new_message_handler.call(message), message]
      end.each do |success, message|
        scrub(message) if success
      end
    end

    def scrub(message)
      if @mailbox.delete_after_delivery
        imap.store(message.seqno, "+FLAGS", [Net::IMAP::DELETED])
      end
    end

    # @private
    # fetch all messages for the new message ids
    def new_messages
      # Both of these calls may results in
      #   imap raising an EOFError, we handle
      #   this exception in the watcher
      messages_for_ids(new_message_ids)
    end

    # TODO: label messages?
    #   @imap.store(id, "+X-GM-LABELS", [label])

    # @private
    # search for all new (unseen) message ids
    # @return [Array<Integer>] message ids
    def new_message_ids
      # uid_search still leaves messages UNSEEN
      imap.uid_search(@mailbox.search_command).select { |uid| @mailbox.deliver?(uid) }
    end

    # @private
    # fetch the email for all given ids in RFC822 format
    # @param ids [Array<Integer>] list of message ids
    # @return [Array<Net::IMAP::FetchData>] the net/imap messages for the given ids
    def messages_for_ids(uids)
      return [] if uids.empty?

      # uid_fetch marks as SEEN, will not be re-fetched for UNSEEN
      imap.uid_fetch(uids, "RFC822")
    end
  end
end
