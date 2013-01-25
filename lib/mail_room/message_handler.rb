module MailRoom
  class MessageHandler
    def process_new_messages
      return if idling? || !running?

      new_messages.each do |msg|
        puts msg.attr['RFC822']

        # @mailbox.delivery_method.deliver(msg.attr['RFC822'])
      end
    end

    def new_messages
      messages_for_ids(new_message_ids)
    end

    # def label_message_with(id, lbl)
    #   in_current_fiber do |f|
    #     @imap.store(id, "+X-GM-LABELS", [lbl]).errback {f.resume}.callback {f.resume}
    #   end
    # end

    def new_message_ids
      @imap.search('UNSEEN')
    end

    def messages_for_ids(ids)
      return [] if ids.empty?

      @imap.fetch(ids, "RFC822")
    end

    def stop_idling
      return unless idling?

      @imap.idle_done
      @idling_thread.join
    end

    def quit
      @running = false
      stop_idling
    end
  end
end
