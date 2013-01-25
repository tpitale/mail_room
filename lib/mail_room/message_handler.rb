module MailRoom
  class MessageHandler
    def initialize(mailbox)
      @mailbox = mailbox
      @imap = Net::IMAP.new('imap.gmail.com', :port => 993, :ssl => true)

      @running = false
      @logged_in = false
      @idling = false
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

    def run
      setup

      @running = true

      @idling_thread = Thread.start do
        while(running?) do
          idle
          fetch_new_messages
        end
      end
    end

    def setup
      log_in
      examine_mailbox
    end

    def log_in
      @imap.login(@mailbox.email, @mailbox.password)
      @logged_in = true
    end

    def examine_mailbox
      return unless logged_in?

      @imap.select(@mailbox.name)
    end

    def fetch_new_messages
      return if idling? || !running?

      new_messages.each do |msg|
        puts msg.attr['RFC822']
        # post_message(msg)
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

    def post_message(msg)
      # connection = Faraday.new
      # connection.token_auth @mailbox["delivery_token"]

      # connection.post do |request|
      #   request.url @mailbox["delivery_url"]
      #   request.options[:timeout] = 3
      #   request.headers['Content-Type'] = 'application/json'
      #   request.body = msg
      # end
    end

    def idle
      return unless logged_in?

      @idling = true

      @imap.idle do |response|
        if response.respond_to?(:name) && response.name == 'EXISTS'
          @imap.idle_done
        end
      end

      @idling = false
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
