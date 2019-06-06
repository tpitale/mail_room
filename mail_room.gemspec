# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mail_room/version'

Gem::Specification.new do |gem|
  gem.name          = "mail_room"
  gem.version       = MailRoom::VERSION
  gem.authors       = ["Tony Pitale"]
  gem.email         = ["tpitale@gmail.com"]
  gem.description   = %q{mail_room will proxy email (gmail) from IMAP to a delivery method}
  gem.summary       = %q{mail_room will proxy email (gmail) from IMAP to a callback URL, logger, or letter_opener}
  gem.homepage      = "http://github.com/tpitale/mail_room"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_development_dependency "rake"
  gem.add_development_dependency "rspec"
  gem.add_development_dependency "mocha"
  gem.add_development_dependency "bourne"
  gem.add_development_dependency "simplecov"

  # for testing delivery methods
  gem.add_development_dependency "faraday"
  gem.add_development_dependency "mail"
  gem.add_development_dependency "letter_opener"
  gem.add_development_dependency "redis-namespace"
  gem.add_development_dependency "pg"
  gem.add_development_dependency "charlock_holmes"
end
