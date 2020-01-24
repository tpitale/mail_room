require 'spec_helper'
require 'mail_room/delivery/postback'

describe MailRoom::Delivery::Postback do
  describe '#deliver' do
    context 'with token auth delivery' do
      let(:mailbox) {build_mailbox({
        :delivery_url => 'http://localhost/inbox',
        :delivery_token => 'abcdefg'
      })}

      let(:delivery_options) {
        MailRoom::Delivery::Postback::Options.new(mailbox)
      }

      it 'posts the message with faraday' do
        connection = stub
        request = stub
        Faraday.stubs(:new).returns(connection)

        connection.stubs(:token_auth)
        connection.stubs(:post).yields(request)

        request.stubs(:url)
        request.stubs(:body=)

        MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')

        expect(connection).to have_received(:token_auth).with('abcdefg')
        expect(connection).to have_received(:post)

        expect(request).to have_received(:url).with('http://localhost/inbox')
        expect(request).to have_received(:body=).with('a message')
      end
    end

    context 'with basic auth delivery options' do
      let(:mailbox) {build_mailbox({
        :delivery_options => {
          :url => 'http://localhost/inbox',
          :username => 'user1',
          :password => 'password123abc'
        }
      })}

      let(:delivery_options) {
        MailRoom::Delivery::Postback::Options.new(mailbox)
      }

      it 'posts the message with faraday' do
        connection = stub
        request = stub
        Faraday.stubs(:new).returns(connection)

        connection.stubs(:basic_auth)
        connection.stubs(:post).yields(request)

        request.stubs(:url)
        request.stubs(:body=)

        MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')

        expect(connection).to have_received(:basic_auth).with('user1', 'password123abc')
        expect(connection).to have_received(:post)

        expect(request).to have_received(:url).with('http://localhost/inbox')
        expect(request).to have_received(:body=).with('a message')
      end

      context 'with content type in the delivery options' do
        let(:mailbox) {build_mailbox({
          :delivery_options => {
            :url => 'http://localhost/inbox',
            :username => 'user1',
            :password => 'password123abc',
            :content_type => 'text/plain'
          }
        })}

  
        let(:delivery_options) {
          MailRoom::Delivery::Postback::Options.new(mailbox)
        }
  
        it 'posts the message with faraday' do
          connection = stub
          request = stub
          Faraday.stubs(:new).returns(connection)
  
          connection.stubs(:basic_auth)
          connection.stubs(:post).yields(request)
  
          request.stubs(:url)
          request.stubs(:body=)
          request.stubs(:headers).returns({})

          MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')
  
          expect(connection).to have_received(:basic_auth).with('user1', 'password123abc')
          expect(connection).to have_received(:post)
          
          expect(request.headers['Content-Type']).to eq('text/plain')
        end
      end
    end
  end
end
