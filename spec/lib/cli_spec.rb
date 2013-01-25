require 'spec_helper'

describe MailRoom::CLI do
  it 'parses arguments into configuration' do
    MailRoom::Configuration.stubs(:new).returns('a config')

    args = ["-c", "a path"]

    MailRoom::CLI.new(args).configuration.should eq('a config')

    MailRoom::Configuration.should have_received(:new).with({:config_path => 'a path'})
  end

  context "when starting" do
    let(:config_path) {File.expand_path('../fixtures/test_config.yml', File.dirname(__FILE__))}
    let(:cli) {MailRoom::CLI.new([])}
    let(:configuration) {MailRoom::Configuration.new({:config_path => config_path})}

    before :each do
      cli.configuration = configuration
    end

    it 'starts running a new coordinator' do
      coordinator = stub(:run)
      MailRoom::Coordinator.stubs(:new).returns(coordinator)

      cli.stubs(:running?).returns(false) # do not loop forever
      cli.start

      MailRoom::Coordinator.should have_received(:new).with(configuration.mailboxes)
      coordinator.should have_received(:run)
    end
  end
end
