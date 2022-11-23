# frozen_string_literal: true

require 'securerandom'
require 'spec_helper'
require 'json'
require 'webmock/rspec'

describe MailRoom::MicrosoftGraph::Connection do
  let(:tenant_id) { options[:inbox_options][:tenant_id] }
  let(:options) do
    {
      delete_after_delivery: true,
      expunge_deleted: true
    }.merge(REQUIRED_MICROSOFT_GRAPH_DEFAULTS)
  end
  let(:mailbox) { build_mailbox(options) }
  let(:graph_endpoint) { 'https://graph.microsoft.com' }
  let(:azure_ad_endpoint) { 'https://login.microsoftonline.com' }
  let(:base_url) { "#{graph_endpoint}/v1.0/users/user@example.com/mailFolders/inbox/messages" }
  let(:message_base_url) { "#{graph_endpoint}/v1.0/users/user@example.com/messages" }

  let(:connection) { described_class.new(mailbox) }
  let(:uid) { 1 }
  let(:access_token) { SecureRandom.hex }
  let(:refresh_token) { SecureRandom.hex }
  let(:expires_in) { Time.now + 3600 }
  let(:unread_messages_body) { '' }
  let(:status) { 200 }
  let!(:stub_token) do
    stub_request(:post, "#{azure_ad_endpoint}/#{tenant_id}/oauth2/v2.0/token").to_return(
      body: { 'access_token' => access_token, 'refresh_token' => refresh_token, 'expires_in' => expires_in }.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end
  let!(:stub_unread_messages_request) do
    stub_request(:get, "#{base_url}?$filter=isRead%20eq%20false").to_return(
      status: status,
      body: unread_messages_body.to_json,
      headers: { 'Content-Type' => 'application/json' }
    )
  end

  before do
    WebMock.enable!
  end

  context '#quit' do
    it 'returns false' do
      expect(connection.stopped?).to be_falsey
    end

    it 'returns true' do
      connection.quit

      expect(connection.stopped?).to be_truthy
    end

    it 'does not attempt to process the mailbox' do
      connection.quit

      connection.expects(:process_mailbox).times(0)
      connection.wait
    end
  end

  context '#wait' do
    before do
      connection.stubs(:do_sleep)
    end

    describe 'poll interval' do
      it 'defaults to 60 seconds' do
        expect(connection.send(:poll_interval)).to eq(60)
      end

      it 'calls do_sleep 60 times' do
        connection.expects(:do_sleep).with(1).times(60)

        connection.wait
      end

      context 'interval set to 10' do
        let(:options) do
          {
            inbox_method: :microsoft_graph,
            inbox_options: {
              tenant_id: '98776',
              client_id: '12345',
              client_secret: 'MY-SECRET',
              poll_interval: '10'
            }
          }
        end

        it 'sets the poll interval to 10' do
          expect(connection.send(:poll_interval)).to eq(10)
        end

        it 'calls do_sleep 10 times' do
          connection.expects(:do_sleep).with(1).times(10)

          connection.wait
        end
      end
    end

    shared_examples 'with a single message' do
      let(:message_id) { SecureRandom.hex }
      let(:unread_messages_body) { { value: ['id' => message_id] } }
      let(:message_url) { "#{message_base_url}/#{message_id}" }
      let(:message_body) { 'hello world' }

      it 'requests message ID' do
        stub_get = stub_request(:get, "#{message_url}/$value").to_return(
          status: 200,
          body: message_body
        )
        stub_patch = stub_request(:patch, message_url).with(body: { "isRead": true }.to_json)
        stub_delete = stub_request(:delete, message_url)
        message_count = 0

        connection.on_new_message do |message|
          message_count += 1
          expect(message.uid).to eq(message_id)
          expect(message.body).to eq(message_body)
        end

        connection.wait

        assert_requested(stub_token)
        assert_requested(stub_unread_messages_request)
        assert_requested(stub_get)
        assert_requested(stub_patch)
        assert_requested(stub_delete)
        expect(message_count).to eq(1)
      end
    end

    context 'with default Azure settings' do
      before do
        puts options
      end
      it_behaves_like 'with a single message'
    end

    # https://docs.microsoft.com/en-us/graph/deployments
    context 'with an alternative Azure deployment' do
      let(:graph_endpoint) { 'https://graph.microsoft.us' }
      let(:azure_ad_endpoint) { 'https://login.microsoftonline.us' }
      let(:options) do
        {
          inbox_method: :microsoft_graph,
          delete_after_delivery: true,
          expunge_deleted: true,
          inbox_options: {
            tenant_id: '98776',
            client_id: '12345',
            client_secret: 'MY-SECRET',
            graph_endpoint: 'https://graph.microsoft.us',
            azure_ad_endpoint: 'https://login.microsoftonline.us'
          }
        }
      end

      it_behaves_like 'with a single message'
    end

    context 'with multiple pages of messages' do
      let(:message_ids) { [SecureRandom.hex, SecureRandom.hex] }
      let(:next_page_url) { "#{graph_endpoint}/v1.0/nextPage" }
      let(:unread_messages_body) { { value: ['id' => message_ids.first], '@odata.nextLink' => next_page_url } }
      let(:message_body) { 'hello world' }

      it 'requests message ID' do
        stub_request(:get, next_page_url).to_return(
          status: 200,
          body: { value: ['id' => message_ids[1]] }.to_json
        )

        stubs = []
        message_ids.each do |message_id|
          rfc822_msg_url = "#{message_base_url}/#{message_id}/$value"
          stubs << stub_request(:get, rfc822_msg_url).to_return(
            status: 200,
            body: message_body
          )

          msg_url = "#{message_base_url}/#{message_id}"
          stubs << stub_request(:patch, msg_url).with(body: { "isRead": true }.to_json)
          stubs << stub_request(:delete, msg_url)
        end

        message_count = 0

        connection.on_new_message do |message|
          expect(message.uid).to eq(message_ids[message_count])
          expect(message.body).to eq(message_body)
          message_count += 1
        end

        connection.wait

        stubs.each { |stub| assert_requested(stub) }
        expect(message_count).to eq(2)
      end
    end

    shared_examples 'request backoff' do
      it 'backs off' do
        connection.expects(:backoff)

        connection.on_new_message {}
        connection.wait

        expect(connection.throttled_count).to eq(1)
      end
    end

    context 'too many requests' do
      let(:status) { 429 }

      it_behaves_like 'request backoff'
    end

    context 'too much bandwidth' do
      let(:status) { 509 }

      it_behaves_like 'request backoff'
    end

    context 'invalid JSON response' do
      let(:body) { 'this is something' }

      it 'ignores the message and logs a warning' do
        mailbox.logger.expects(:warn)

        connection.on_new_message {}
        connection.wait
      end
    end

    context '500 error' do
      let(:status) { 500 }

      it 'terminates due to error' do
        connection.on_new_message {}

        expect { connection.wait }.to raise_error(OAuth2::Error)
      end
    end
  end
end
