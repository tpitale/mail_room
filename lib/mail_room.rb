require 'net/imap'
require 'optparse'
require 'yaml'
require 'daemons'

module MailRoom
end

require "mail_room/version"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/mailbox_watcher"
require "mail_room/mailbox_handler"
require "mail_room/coordinator"
require "mail_room/cli"
