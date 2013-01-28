require 'spec_helper'
require 'mail_room/delivery/letter_opener'

describe MailRoom::Delivery::LetterOpener do
  describe '#deliver' do
    let(:mailbox) {MailRoom::Mailbox.new(:location => '/tmp/somewhere')}
    let(:delivery_method) {stub(:deliver!)}
    let(:mail) {stub}

    before :each do
      Mail.stubs(:read_from_string).returns(mail)
      ::LetterOpener::DeliveryMethod.stubs(:new).returns(delivery_method)

      MailRoom::Delivery::LetterOpener.new(mailbox).deliver('a message')
    end

    it 'creates a new LetterOpener::DeliveryMethod' do
      ::LetterOpener::DeliveryMethod.should have_received(:new).with(:location => '/tmp/somewhere')
    end

    it 'parses the message string with Mail' do
      ::Mail.should have_received(:read_from_string).with('a message')
    end

    it 'delivers the mail message' do
      delivery_method.should have_received(:deliver!).with(mail)
    end
  end
end