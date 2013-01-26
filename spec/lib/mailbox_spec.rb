require 'spec_helper'

describe MailRoom::Mailbox do
  describe "#deliver" do
    context "with delivery_method of noop" do
      it 'delivers with a Noop instance' do
        mailbox = MailRoom::Mailbox.new({:delivery_method => 'noop'})
        noop = stub(:deliver)
        MailRoom::Delivery::Noop.stubs(:new => noop)

        mailbox.deliver(stub(:attr => {'RFC822' => 'a message'}))

        noop.should have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of logger" do
      it 'delivers with a Logger instance' do
        mailbox = MailRoom::Mailbox.new({:delivery_method => 'logger'})
        logger = stub(:deliver)
        MailRoom::Delivery::Logger.stubs(:new => logger)

        mailbox.deliver(stub(:attr => {'RFC822' => 'a message'}))

        logger.should have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of postback" do
      it 'delivers with a Postback instance' do
        mailbox = MailRoom::Mailbox.new({:delivery_method => 'postback'})
        postback = stub(:deliver)
        MailRoom::Delivery::Postback.stubs(:new => postback)

        mailbox.deliver(stub(:attr => {'RFC822' => 'a message'}))

        postback.should have_received(:deliver).with('a message')
      end
    end

    context "with delivery_method of letter_opener" do
      it 'delivers with a LetterOpener instance' do
        mailbox = MailRoom::Mailbox.new({:delivery_method => 'letter_opener'})
        letter_opener = stub(:deliver)
        MailRoom::Delivery::LetterOpener.stubs(:new => letter_opener)

        mailbox.deliver(stub(:attr => {'RFC822' => 'a message'}))

        letter_opener.should have_received(:deliver).with('a message')
      end
    end
  end
end
