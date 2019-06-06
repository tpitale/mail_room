require 'spec_helper'
require 'mail_room/arbitration/redis'

describe MailRoom::Arbitration::Redis do
  let(:mailbox) {
    MailRoom::Mailbox.new(
      arbitration_options: {
        namespace: "mail_room"
      }
    )
  }
  let(:options) { described_class::Options.new(mailbox) }
  subject       { described_class.new(options) }

  # Private, but we don't care.
  let(:client) { subject.send(:client) }

  describe '#deliver?' do
    context "when called the first time" do
      it "returns true" do
        expect(subject.deliver?(123)).to be_truthy
      end

      it "increments the delivered flag" do
        subject.deliver?(123)

        expect(client.get("delivered:123")).to eq("1")
      end

      it "sets an expiration on the delivered flag" do
        subject.deliver?(123)

        expect(client.ttl("delivered:123")).to be > 0
      end
    end

    context "when called the second time" do
      before do
        #Short expiration, for testing
        subject.deliver?(123, 2)
      end

      it "returns false" do
        # Fails locally because fakeredis returns 0, not false
        expect(subject.deliver?(123, 2)).to be_falsey
      end

      it "after expiration returns true" do
        # Fails locally because fakeredis returns 0, not false
        expect(subject.deliver?(123, 2)).to be_falsey
        sleep(client.ttl("delivered:123")+1)
        expect(subject.deliver?(123, 2)).to be_truthy
      end
    end

    context "when called for another uid" do
      before do
        subject.deliver?(123)
      end

      it "returns true" do
        expect(subject.deliver?(234)).to be_truthy
      end
    end
  end

  context 'redis client connection params' do
    context 'when only url is present' do
      let(:redis_url) { "redis://redis.example.com:8888" }
      let(:mailbox) {
        MailRoom::Mailbox.new(
          arbitration_options: {
            redis_url: redis_url
          }
        )
      }

      it 'client has same specified url' do
        subject.deliver?(123)

        expect(client.options[:url]).to eq redis_url
      end

      it 'client is a instance of Redis class' do
        expect(client).to be_a Redis
      end
    end

    context 'when namespace is present' do
      let(:namespace) { 'mail_room' }
      let(:mailbox) {
        MailRoom::Mailbox.new(
          arbitration_options: {
            namespace: namespace
          }
        )
      }

      it 'client has same specified namespace' do
        expect(client.namespace).to eq(namespace)
      end

      it 'client is a instance of RedisNamespace class' do
        expect(client).to be_a ::Redis::Namespace
      end
    end

    context 'when sentinel is present' do
      let(:redis_url) { 'redis://:mypassword@sentinel-master:6379' }
      let(:sentinels) { [{ host: '10.0.0.1', port: '26379' }] }
      let(:mailbox) {
        MailRoom::Mailbox.new(
          arbitration_options: {
            redis_url: redis_url,
            sentinels: sentinels
          }
        )
      }

      before { ::Redis::Client::Connector::Sentinel.any_instance.stubs(:resolve).returns(sentinels) }

      it 'client has same specified sentinel params' do
        expect(client.client.instance_variable_get(:@connector)).to be_a Redis::Client::Connector::Sentinel
        expect(client.client.options[:host]).to eq('sentinel-master')
        expect(client.client.options[:password]).to eq('mypassword')
        expect(client.client.options[:sentinels]).to eq(sentinels)
      end
    end
  end
end
