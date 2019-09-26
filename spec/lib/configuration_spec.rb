require 'spec_helper'

describe MailRoom::Configuration do
  let(:config_path) {File.expand_path('../fixtures/test_config.yml', File.dirname(__FILE__))}

  describe 'set_mailboxes' do
    context 'with config_path' do
      let(:configuration) { MailRoom::Configuration.new(:config_path => config_path) }

      it 'parses yaml into mailbox objects' do
        MailRoom::Mailbox.stubs(:new).returns('mailbox1', 'mailbox2')

        expect(configuration.mailboxes).to eq(['mailbox1', 'mailbox2'])
      end

      it 'sets logger with filename if structured logfile is specified' do
        mailbox_with_logfile = configuration.mailboxes[0]
        expect(mailbox_with_logfile.structured_logger.noop?).to be_falsey
      end

      it 'sets logger to no-op if no structured logfile is specified' do
        # this also matches existing behaviour, so should have no effect if someone upgrades from a previous version
        mailbox_without_logfile = configuration.mailboxes[1]
        expect(mailbox_without_logfile.structured_logger.noop?).to be_truthy
      end
    end

    context 'without config_path' do
      let(:configuration) { MailRoom::Configuration.new }

      it 'sets mailboxes to an empty set' do
        MailRoom::Mailbox.stubs(:new)

        expect(configuration.mailboxes).to eq([])

        expect(MailRoom::Mailbox).to have_received(:new).never
      end
    end
  end
end
