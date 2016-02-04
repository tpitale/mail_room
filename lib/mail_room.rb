require 'net/imap'
require 'optparse'
require 'yaml'
require 'logger'

module MailRoom
  def self.logger
    @logger ||= Logger.new(STDOUT)
  end

  def self.logger=(logger)
    @logger = (logger ? logger : Logger.new("/dev/null"))
  end
end

require "mail_room/version"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/mailbox_watcher"
require "mail_room/mailbox_handler"
require "mail_room/coordinator"
require "mail_room/cli"
