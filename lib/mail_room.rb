require 'net/imap'
require 'optparse'
require 'yaml'

module MailRoom
  # def self.logger
  #   @logger ||= Logger.new(STDOUT)
  # end
end

require "mail_room/version"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/mailbox_watcher"
require "mail_room/message_handler"
require "mail_room/coordinator"
require "mail_room/cli"
