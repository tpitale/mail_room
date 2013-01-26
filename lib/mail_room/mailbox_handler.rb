module MailRoom
  class MailboxHandler
    def initialize(mailbox, imap)
      @mailbox = mailbox
      @imap = imap
    end

    def process
      # return if idling? || !running?

      new_messages.each do |msg|
        # puts msg.attr['RFC822']

        # loop over delivery methods and deliver each
        @mailbox.deliver(msg)
      end
    end

    def new_messages
      messages_for_ids(new_message_ids)
    end

    # label messages?
    # @imap.store(id, "+X-GM-LABELS", [label])

    def new_message_ids
      @imap.search('UNSEEN')
    end

    def messages_for_ids(ids)
      return [] if ids.empty?

      @imap.fetch(ids, "RFC822")
    end
  end
end
