module MailRoom
  # Fetches new email messages for delivery
  # @author Tony Pitale
  class MailboxHandler
    # build a handler for this mailbox and our imap connection
    # @param mailbox [MailRoom::Mailbox] the mailbox configuration
    # @param imap [Net::IMAP::Connection] the open connection to gmail
    def initialize(mailbox, imap)
      @mailbox = mailbox
      @imap = imap
    end

    # deliver each of the new messages
    def process
      # return if idling? || !running?

      new_messages.each do |message|
        # loop over delivery methods and deliver each
        delivered = @mailbox.deliver(message)

        if delivered && @mailbox.delete_after_delivery
          @imap.store(message.seqno, "+FLAGS", [Net::IMAP::DELETED])
        end
      end

      @imap.expunge if @mailbox.delete_after_delivery
    end

    private
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
      uids = @imap.uid_search(@mailbox.search_command)
      uids.select! { |uid| @mailbox.deliver?(uid) }
      uids
    end

    # @private
    # fetch the email for all given ids in RFC822 format
    # @param ids [Array<Integer>] list of message ids
    # @return [Array<Net::IMAP::FetchData>] the net/imap messages for the given ids
    def messages_for_ids(uids)
      return [] if uids.empty?

      @imap.uid_fetch(uids, "RFC822")
    end
  end
end
