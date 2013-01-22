require 'celluloid'
require 'net/imap'
require 'fileutils'
require 'optparse'
require 'yaml'

module Owney
end

require "owney/version"
require "owney/configuration"
require "owney/mailbox"
require "owney/message_handler"
require "owney/coordinator"
require "owney/cli"
