require 'spec_helper'
require 'mail_room/delivery/letter_opener'

describe MailRoom::Delivery::LetterOpener do
  describe '#deliver' do
    let(:mailbox) {build_mailbox(:location => '/tmp/somewhere')}
    let(:delivery_method) {stub(:deliver!)}
    let(:mail) {stub}

    before :each do
      Mail.stubs(:read_from_string).returns(mail)
      ::LetterOpener::DeliveryMethod.stubs(:new).returns(delivery_method)
    end

    it 'creates a new LetterOpener::DeliveryMethod' do
      ::LetterOpener::DeliveryMethod.expects(:new).with(:location => '/tmp/somewhere').returns(delivery_method)

      MailRoom::Delivery::LetterOpener.new(mailbox).deliver('a message')
    end

    it 'parses the message string with Mail' do
      ::Mail.expects(:read_from_string).with('a message')

      MailRoom::Delivery::LetterOpener.new(mailbox).deliver('a message')
    end

    it 'delivers the mail message' do
      delivery_method.expects(:deliver!).with(mail)

      MailRoom::Delivery::LetterOpener.new(mailbox).deliver('a message')
    end
  end
end