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
  let(:base_url) { 'https://graph.microsoft.com/v1.0/users/user@example.com/mailFolders/inbox/messages' }
  let(:message_base_url) { 'https://graph.microsoft.com/v1.0/users/user@example.com/messages' }

  before do
    WebMock.enable!
  end

  context '#wait' do
    let(:connection) { described_class.new(mailbox) }
    let(:uid) { 1 }
    let(:access_token) { SecureRandom.hex }
    let(:refresh_token) { SecureRandom.hex }
    let(:expires_in) { Time.now + 3600 }
    let(:unread_messages_body) { '' }
    let(:status) { 200 }
    let!(:stub_token) do
      stub_request(:post, "https://login.microsoftonline.com/#{tenant_id}/oauth2/v2.0/token").to_return(
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
      connection.stubs(:wait_for_new_messages)
    end

    context 'with a single message' do
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

    context 'with multiple pages of messages' do
      let(:message_ids) { [SecureRandom.hex, SecureRandom.hex] }
      let(:next_page_url) { 'https://graph.microsoft.com/v1.0/nextPage' }
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

    context 'too many requests' do
      let(:status) { 429 }

      it 'backs off' do
        connection.expects(:backoff)

        connection.on_new_message {}
        connection.wait

        expect(connection.throttled_count).to eq(1)
      end
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

      it 'resets the state and logs a warning' do
        connection.expects(:reset)
        connection.expects(:setup)
        mailbox.logger.expects(:warn)

        connection.on_new_message {}
        connection.wait
      end
    end
  end
end
