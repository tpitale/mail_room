module MailRoom
  class IMAP < Net::IMAP
    # Backported 2.3.0 version of net/imap idle command to support timeout
    def idle(timeout = nil, &response_handler)
      raise LocalJumpError, "no block given" unless response_handler

      response = nil

      synchronize do
        tag = Thread.current[:net_imap_tag] = generate_tag
        put_string("#{tag} IDLE#{CRLF}")

        begin
          add_response_handler(response_handler)
          @idle_done_cond = new_cond
          @idle_done_cond.wait(timeout)
          @idle_done_cond = nil
          if @receiver_thread_terminating
            raise Net::IMAP::Error, "connection closed"
          end
        ensure
          unless @receiver_thread_terminating
            remove_response_handler(response_handler)
            put_string("DONE#{CRLF}")
            response = get_tagged_response(tag, "IDLE")
          end
        end
      end

      return response
    end unless public_method_defined?(:idle)
  end
end
