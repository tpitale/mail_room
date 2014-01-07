require 'spec_helper'

describe MailRoom::CLI do
  let(:config_path) {File.expand_path('../fixtures/test_config.yml', File.dirname(__FILE__))}
  let!(:configuration) {MailRoom::Configuration.new({:config_path => config_path})}
  let(:coordinator) {stub(:run => true, :quit => true)}

  describe '.new' do
    let(:args) {["-c", "a path"]}

    before :each do
      MailRoom::Configuration.stubs(:new).returns(configuration)
      MailRoom::Coordinator.stubs(:new).returns(coordinator)
    end

    it 'parses arguments into configuration' do
      MailRoom::CLI.new(args).configuration.should eq(configuration)
      MailRoom::Configuration.should have_received(:new).with({:config_path => 'a path'})
    end

    it 'creates a new coordinator with configuration' do
      MailRoom::CLI.new(args).coordinator.should eq(coordinator)
      MailRoom::Coordinator.should have_received(:new).with(configuration.mailboxes)
    end
  end

  describe '#start' do
    let(:cli) {MailRoom::CLI.new([])}

    before :each do
      cli.configuration = configuration
      cli.coordinator = coordinator
    end

    it 'starts running the coordinator' do
      cli.start

      coordinator.should have_received(:run)
    end
  end
end
