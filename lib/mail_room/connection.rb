# frozen_string_literal: true

module MailRoom
  module Connection
    autoload :Base, 'mail_room/connection/base'
    autoload :IMAP, 'mail_room/connection/imap'
  end
end
