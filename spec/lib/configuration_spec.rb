require 'spec_helper'

describe MailRoom::Configuration do
  let(:config_path) {File.expand_path('../fixtures/test_config.yml', File.dirname(__FILE__))}

  describe '#initalize' do
    context 'with config_path' do
      let(:configuration) { MailRoom::Configuration.new(config_path: config_path) }

      it 'parses yaml into mailbox objects' do
        MailRoom::Mailbox.stubs(:new).returns('mailbox1', 'mailbox2')

        expect(configuration.mailboxes).to eq(['mailbox1', 'mailbox2'])
      end

      it 'parses health check' do
        expect(configuration.health_check).to be_a(MailRoom::HealthCheck)
      end
    end

    context 'without config_path' do
      let(:configuration) { MailRoom::Configuration.new }

      it 'sets mailboxes to an empty set' do
        MailRoom::Mailbox.stubs(:new)
        MailRoom::Mailbox.expects(:new).never

        expect(configuration.mailboxes).to eq([])
      end

      it 'sets the health check to nil' do
        expect(configuration.health_check).to be_nil
      end
    end
  end
end
