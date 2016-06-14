require 'simplecov'
SimpleCov.start

require 'bundler/setup'

require 'rspec'
require 'mocha/api'
require 'bourne'
require 'fakeredis/rspec'

require File.expand_path('../../lib/mail_room', __FILE__)

RSpec.configure do |config|
  config.mock_with :mocha
  config.expect_with(:rspec) { |c| c.syntax = [:expect, :should] }
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'
end
