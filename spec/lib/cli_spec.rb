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
      expect(MailRoom::CLI.new(args).configuration).to eq(configuration)
      expect(MailRoom::Configuration).to have_received(:new).with({:config_path => 'a path'})
    end

    it 'creates a new coordinator with configuration' do
      expect(MailRoom::CLI.new(args).coordinator).to eq(coordinator)
      expect(MailRoom::Coordinator).to have_received(:new).with(configuration.mailboxes)
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

      expect(coordinator).to have_received(:run)
    end

    context 'on error' do
      let(:error_message) { "oh noes!" }
      let(:coordinator) { OpenStruct.new(run: true, quit: true) }

      before do
        cli.instance_variable_set(:@options, {exit_error_format: error_format})
        coordinator.stubs(:run).raises(RuntimeError, error_message)
      end

      context 'json format provided' do
        let(:error_format) { 'json' }

        it 'passes onto CrashHandler' do
          cli.start

          expect(MailRoom::CrashHandler).to have_received(:new).with a_hash_including({format: error_format})
        end
      end
    end
  end
end
