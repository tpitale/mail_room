require 'net/imap'
require 'optparse'
require 'yaml'

module MailRoom
end

require "mail_room/version"
require "mail_room/backports/imap"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/mailbox_watcher"
require "mail_room/connection"
require "mail_room/coordinator"
require "mail_room/cli"
