# frozen_string_literal:true

module MailRoom
  module IMAP
    class Message < MailRoom::Message
      attr_reader :seqno

      def initialize(uid:, body:, seqno:)
        super(uid: uid, body: body)

        @seqno = seqno
      end

      def ==(other)
        super && seqno == other.seqno
      end
    end
  end
end
