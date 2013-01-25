require 'net/imap'
require 'fileutils'
require 'optparse'
require 'yaml'

module MailRoom
end

require "mail_room/version"
require "mail_room/configuration"
require "mail_room/mailbox"
require "mail_room/message_handler"
require "mail_room/coordinator"
require "mail_room/cli"
