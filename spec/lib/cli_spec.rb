require 'spec_helper'

describe MailRoom::CLI do
  let(:config_path) {File.expand_path('../fixtures/test_config.yml', File.dirname(__FILE__))}
  let!(:configuration) {MailRoom::Configuration.new({:config_path => config_path})}
  let(:coordinator) {stub(:run => true, :quit => true)}
  let(:configuration_args) { anything }
  let(:coordinator_args) { anything }

  describe '.new' do
    let(:args) {["-c", "a path"]}

    before :each do
      MailRoom::Configuration.expects(:new).with(configuration_args).returns(configuration)
      MailRoom::Coordinator.stubs(:new).with(coordinator_args).returns(coordinator)
    end

    context 'with configuration args' do
      let(:configuration_args) do
        {:config_path => 'a path'}
      end

      it 'parses arguments into configuration' do
        expect(MailRoom::CLI.new(args).configuration).to eq configuration
      end
    end

    context 'with coordinator args' do
      let(:coordinator_args) do
        configuration.mailboxes
      end

      it 'creates a new coordinator with configuration' do
        expect(MailRoom::CLI.new(args).coordinator).to eq(coordinator)
      end
    end
  end

  describe '#start' do
    let(:cli) {MailRoom::CLI.new([])}

    before :each do
      cli.configuration = configuration
      cli.coordinator = coordinator
      cli.stubs(:exit)
    end

    it 'starts running the coordinator' do
      coordinator.expects(:run)

      cli.start
    end

    context 'on error' do
      let(:error) { RuntimeError.new("oh noes!") }
      let(:coordinator) { stub(run: true, quit: true) }
      let(:crash_handler) { stub(handle: nil) }

      before do
        cli.instance_variable_set(:@options, {exit_error_format: error_format})
        coordinator.stubs(:run).raises(error)
        MailRoom::CrashHandler.stubs(:new).returns(crash_handler)
      end

      context 'json format provided' do
        let(:error_format) { 'json' }

        it 'passes onto CrashHandler' do
          handler.expects(:handle).with(error, error_format)

          cli.start
        end
      end
    end
  end
end
