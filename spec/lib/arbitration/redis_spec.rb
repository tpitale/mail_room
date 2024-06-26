require 'spec_helper'
require 'mail_room/arbitration/redis'

describe MailRoom::Arbitration::Redis do
  let(:mailbox) {
    build_mailbox(
      arbitration_options: {
        namespace: "mail_room",
        redis_url: ENV['REDIS_URL']
      }
    )
  }
  let(:options) { described_class::Options.new(mailbox) }
  subject       { described_class.new(options) }

  # Private, but we don't care.
  let(:redis) { subject.send(:client) }
  let(:raw_client) { redis._client }

  describe '#deliver?' do
    context "when called the first time" do
      after do
        redis.del("delivered:123")
      end

      it "returns true" do
        expect(subject.deliver?(123)).to be_truthy
      end

      it "increments the delivered flag" do
        subject.deliver?(123)

        expect(redis.get("delivered:123")).to eq("1")
      end

      it "sets an expiration on the delivered flag" do
        subject.deliver?(123)

        expect(redis.ttl("delivered:123")).to be > 0
      end
    end

    context "when called the second time" do
      before do
        #Short expiration, 1 second, for testing
        subject.deliver?(123, 1)
      end

      after do
        redis.del("delivered:123")
      end

      it "returns false" do
        expect(subject.deliver?(123, 1)).to be_falsey
      end

      it "after expiration returns true" do
        # Fails locally because fakeredis returns 0, not false
        expect(subject.deliver?(123, 1)).to be_falsey
        sleep(redis.ttl("delivered:123")+1)
        expect(subject.deliver?(123, 1)).to be_truthy
      end
    end

    context "when called for another uid" do
      before do
        subject.deliver?(123)
      end

      after do
        redis.del("delivered:123")
        redis.del("delivered:124")
      end

      it "returns true" do
        expect(subject.deliver?(124)).to be_truthy
      end
    end
  end

  context 'redis client connection params' do
    context 'when only url is present' do
      let(:redis_url) { ENV.fetch('REDIS_URL', 'redis://localhost:6379') }
      let(:mailbox) {
        build_mailbox(
          arbitration_options: {
            redis_url: redis_url
          }
        )
      }

      after do
        redis.del("delivered:123")
      end

      it 'client has same specified url' do
        subject.deliver?(123)

        expect(raw_client.config.server_url).to eq redis_url
      end

      it 'client is a instance of Redis class' do
        expect(redis).to be_a Redis
      end
    end

    context 'when namespace is present' do
      let(:namespace) { 'mail_room' }
      let(:mailbox) {
        build_mailbox(
          arbitration_options: {
            namespace: namespace
          }
        )
      }

      it 'client has same specified namespace' do
        expect(redis.namespace).to eq(namespace)
      end

      it 'client is a instance of RedisNamespace class' do
        expect(redis).to be_a ::Redis::Namespace
      end
    end

    context 'when sentinel is present' do
      let(:redis_url) { 'redis://:mypassword@sentinel-master:6379' }
      let(:sentinels) { [{ host: '10.0.0.1', port: '26379' }] }
      let(:mailbox) {
        build_mailbox(
          arbitration_options: {
            redis_url: redis_url,
            sentinels: sentinels
          }
        )
      }

      before { ::RedisClient::SentinelConfig.any_instance.stubs(:resolve_master).returns(RedisClient::Config.new(**sentinels.first)) }

      it 'client has same specified sentinel params' do
        expect(raw_client.config).to be_a RedisClient::SentinelConfig
        expect(raw_client.config.name).to eq('sentinel-master')
        expect(raw_client.config.host).to eq('10.0.0.1')
        expect(raw_client.config.password).to eq('mypassword')
        expect(raw_client.config.sentinels.map(&:server_url)).to eq(["redis://10.0.0.1:26379"])
      end

      context 'with separate Sentinel username and password' do
        let(:sentinel_username) { 'my-sentinel-user' }
        let(:sentinel_password) { 'my-sentinel-pass' }
        let(:mailbox) {
          build_mailbox(
            arbitration_options: {
              redis_url: redis_url,
              sentinels: sentinels,
              sentinel_username: sentinel_username,
              sentinel_password: sentinel_password
            }
          )
        }

        it 'client uses Sentinel username and password' do
          expect(raw_client.config).to be_a RedisClient::SentinelConfig
          expect(raw_client.config.password).to eq('mypassword')

          sentinels = raw_client.config.sentinels
          expect(sentinels.map(&:username).uniq).to eq([sentinel_username])
          expect(sentinels.map(&:password).uniq).to eq([sentinel_password])
        end
      end
    end
  end
end
