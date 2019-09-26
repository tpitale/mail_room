require 'spec_helper'
require 'mail_room/delivery/logger'

describe MailRoom::Delivery::Logger do
  describe '#initialize' do
    context "without a log path" do
      let(:mailbox) {build_mailbox}

      it 'creates a new ruby logger' do
        ::Logger.stubs(:new)

        MailRoom::Delivery::Logger.new(mailbox)

        expect(::Logger).to have_received(:new).with(STDOUT)
      end
    end

    context "with a log path" do
      let(:mailbox) {build_mailbox(:log_path => '/var/log/mail-room.log')}

      it 'creates a new file to append to' do
        ::Logger.stubs(:new)
        file = stub(:sync=)
        ::File.stubs(:open).returns(file)

        MailRoom::Delivery::Logger.new(mailbox)

        expect(File).to have_received(:open).with('/var/log/mail-room.log', 'a')
        expect(::Logger).to have_received(:new).with(file)
      end
    end
  end

  describe '#deliver' do
    let(:mailbox) {build_mailbox}

    it 'writes the message to info' do
      logger = stub(:info)
      ::Logger.stubs(:new).returns(logger)

      MailRoom::Delivery::Logger.new(mailbox).deliver('a message')

      expect(logger).to have_received(:info).with('a message')
    end
  end
end
