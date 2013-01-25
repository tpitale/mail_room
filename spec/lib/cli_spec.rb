require 'spec_helper'

describe MailRoom::CLI do
  it 'parses arguments into configuration' do
    MailRoom::Configuration.stubs(:new).returns('a config')

    args = ["-c", "a path"]

    MailRoom::CLI.new(args).configuration.should eq('a config')

    MailRoom::Configuration.should have_received(:new).with({:config_path => 'a path'})
  end
end
