require 'spec_helper'
require 'mail_room/delivery/postback'

describe MailRoom::Delivery::Postback do
  describe '#deliver' do
    context 'with token auth delivery' do
      let(:mailbox) {build_mailbox({
        delivery_url: 'http://localhost/inbox',
        delivery_token: 'abcdefg'
      })}

      let(:delivery_options) {
        MailRoom::Delivery::Postback::Options.new(mailbox)
      }

      it 'posts the message with faraday' do
        connection = stub
        request = stub
        Faraday.stubs(:new).returns(connection)

        connection.expects(:token_auth).with('abcdefg')
        connection.expects(:post).yields(request)

        request.expects(:url).with('http://localhost/inbox')
        request.expects(:body=).with('a message')

        MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')
      end
    end

    context 'with basic auth delivery options' do
      let(:mailbox) {build_mailbox({
        delivery_options: {
          url: 'http://localhost/inbox',
          username: 'user1',
          password: 'password123abc'
        }
      })}

      let(:delivery_options) {
        MailRoom::Delivery::Postback::Options.new(mailbox)
      }

      it 'posts the message with faraday' do
        connection = stub
        request = stub
        Faraday.stubs(:new).returns(connection)

        connection.expects(:basic_auth).with('user1', 'password123abc')
        connection.expects(:post).yields(request)

        request.expects(:url).with('http://localhost/inbox')
        request.expects(:body=).with('a message')

        MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')
      end

      context 'with content type in the delivery options' do
        let(:mailbox) {build_mailbox({
          delivery_options: {
            url: 'http://localhost/inbox',
            username: 'user1',
            password: 'password123abc',
            content_type: 'text/plain'
          }
        })}

  
        let(:delivery_options) {
          MailRoom::Delivery::Postback::Options.new(mailbox)
        }
  
        it 'posts the message with faraday' do
          connection = stub
          request = stub
          Faraday.stubs(:new).returns(connection)

          connection.expects(:post).yields(request)
          request.stubs(:url)
          request.stubs(:body=)
          request.stubs(:headers).returns({})
          connection.expects(:basic_auth).with('user1', 'password123abc')

          MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')
          
          expect(request.headers['Content-Type']).to eq('text/plain')
        end
      end
    end
  end
end
