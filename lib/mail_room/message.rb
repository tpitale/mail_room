# frozen_string_literal: true

module MailRoom
  class Message
    attr_reader :uid, :body

    def initialize(uid:, body:)
      @uid = uid
      @body = body
    end

    def ==(other)
      self.class == other.class && uid == other.uid && body == other.body
    end
  end
end
