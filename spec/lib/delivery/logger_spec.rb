require 'spec_helper'
require 'mail_room/delivery/logger'

describe MailRoom::Delivery::Logger do
  describe '#initialize' do
    context "without a log path" do
      let(:mailbox) {build_mailbox}

      it 'creates a new ruby logger' do
        ::Logger.stubs(:new)

        ::Logger.expects(:new).with(STDOUT)

        MailRoom::Delivery::Logger.new(mailbox)
      end
    end

    context "with a log path" do
      let(:mailbox) {build_mailbox(log_path: '/var/log/mail-room.log')}

      it 'creates a new file to append to' do
        file = stub
        file.stubs(:sync=)

        File.expects(:open).with('/var/log/mail-room.log', 'a').returns(file)
        ::Logger.stubs(:new).with(file)

        MailRoom::Delivery::Logger.new(mailbox)
      end
    end
  end

  describe '#deliver' do
    let(:mailbox) {build_mailbox}

    it 'writes the message to info' do
      logger = stub(:info)
      ::Logger.stubs(:new).returns(logger)

      logger.expects(:info).with('a message')

      MailRoom::Delivery::Logger.new(mailbox).deliver('a message')
    end
  end
end
