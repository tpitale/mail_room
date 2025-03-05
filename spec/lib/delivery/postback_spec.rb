require 'spec_helper'
require 'mail_room/delivery/postback'
require 'tempfile'
require 'webmock/rspec'

describe MailRoom::Delivery::Postback do
  describe '#deliver' do
    let(:delivery_options) do
      MailRoom::Delivery::Postback::Options.new(mailbox)
    end

    before do
      stub_request(:post, 'http://localhost/inbox')
        .with(body: 'a message', headers: headers)
        .to_return(status: 201)
    end

    shared_examples 'message poster' do
      it 'posts the message with faraday' do
        MailRoom::Delivery::Postback.new(delivery_options).deliver('a message')
      end
    end

    context 'with token auth delivery' do
      let(:mailbox) do
        build_mailbox({
                        delivery_url: 'http://localhost/inbox',
                        delivery_token: 'abcdefg'
                      })
      end

      let(:headers) { { 'Authorization' => 'Token abcdefg' } }

      it_behaves_like 'message poster'
    end

    context 'with basic auth delivery options' do
      let(:mailbox) do
        build_mailbox({
                        delivery_options: {
                          url: 'http://localhost/inbox',
                          username: 'user1',
                          password: 'password123abc'
                        }
                      })
      end

      let(:headers) { { 'Authorization' => 'Basic dXNlcjE6cGFzc3dvcmQxMjNhYmM=' } }

      it_behaves_like 'message poster'

      context 'with content type in the delivery options' do
        let(:mailbox) do
          build_mailbox({
                          delivery_options: {
                            url: 'http://localhost/inbox',
                            username: 'user1',
                            password: 'password123abc',
                            content_type: 'text/plain'
                          }
                        })
        end

        let(:headers) do
          {
            'Authorization' => 'Basic dXNlcjE6cGFzc3dvcmQxMjNhYmM=',
            'Content-Type' => 'text/plain'
          }
        end

        it_behaves_like 'message poster'
      end

      context 'with jwt token in the delivery options' do
        let(:mailbox) do
          build_mailbox({
                          delivery_options: {
                            url: 'http://localhost/inbox',
                            jwt_auth_header: "Mailroom-Api-Request",
                            jwt_issuer: "mailroom",
                            jwt_algorithm: "HS256",
                            jwt_secret_path: jwt_secret.path,
                            content_type: 'application/json'
                          }
                        })
        end

        let(:headers) do
          {
            'Content-Type' => 'application/json',
            'Mailroom-Api-Request' => /.*/
          }
        end

        let(:jwt_secret) do
          file = Tempfile.new('secret')
          file.write("test secret")
          file
        end

        after do
          jwt_secret.unlink
        end

        it_behaves_like 'message poster'
      end
    end
  end
end
