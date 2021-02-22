require 'net/imap'
require 'optparse'
require 'yaml'

module MailRoom
end

require "mail_room/version"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/mailbox_watcher"
require "mail_room/message"
require "mail_room/connection"
require "mail_room/coordinator"
require "mail_room/cli"
require 'mail_room/logger/structured'
require 'mail_room/crash_handler'
