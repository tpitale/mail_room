require 'spec_helper'
require 'mail_room/delivery/postback'

describe MailRoom::Delivery::Postback do
  describe '#deliver' do
    let(:mailbox) {MailRoom::Mailbox.new({
      :delivery_url => 'http://localhost/inbox',
      :delivery_token => 'abcdefg'
    })}

    it 'posts the message with faraday' do
      connection = stub
      request = stub
      Faraday.stubs(:new).returns(connection)

      connection.stubs(:token_auth)
      connection.stubs(:post).yields(request)

      request.stubs(:url)
      request.stubs(:body=)

      MailRoom::Delivery::Postback.new(mailbox).deliver('a message')

      expect(connection).to have_received(:token_auth).with('abcdefg')
      expect(connection).to have_received(:post)

      expect(request).to have_received(:url).with('http://localhost/inbox')
      expect(request).to have_received(:body=).with('a message')
    end
  end
end
