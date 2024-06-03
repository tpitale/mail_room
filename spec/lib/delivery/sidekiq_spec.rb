require 'spec_helper'
require 'mail_room/delivery/sidekiq'

describe MailRoom::Delivery::Sidekiq do
  subject { described_class.new(options) }
  let(:redis) { subject.send(:client) }
  let(:raw_client) { redis._client }
  let(:options) { MailRoom::Delivery::Sidekiq::Options.new(mailbox) }

  describe '#options' do
    let(:redis_url) { 'redis://localhost:6379' }
    let(:redis_options) { { redis_url: redis_url } }

    context 'when only redis_url is specified' do
      let(:mailbox) {
        build_mailbox(
          delivery_method: :sidekiq,
          delivery_options: redis_options
        )
      }

      context 'with simple redis url' do
        it 'client has same specified redis_url' do
          expect(raw_client.config.server_url).to eq(redis_url)
        end

        it 'client is a instance of RedisNamespace class' do
          expect(redis).to be_a ::Redis
        end

        it 'connection has correct values' do
          expect(redis.connection[:host]).to eq('localhost')
          expect(redis.connection[:db]).to eq(0)
        end
      end

      context 'with redis_db specified in options' do
        before do
          redis_options[:redis_db] = 4
        end

        it 'client has correct redis_url' do
          expect(raw_client.config.server_url).to eq("#{redis_url}/4")
        end

        it 'connection has correct values' do
          expect(raw_client.config.host).to eq('localhost')
          expect(raw_client.config.db).to eq(4)
        end
      end
    end

    context 'when namespace is specified' do
      let(:namespace) { 'sidekiq_mailman' }
      let(:mailbox) {
        build_mailbox(
          delivery_method: :sidekiq,
          delivery_options: {
            redis_url: redis_url,
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

    context 'when sentinel is specified' do
      let(:redis_url) { 'redis://:mypassword@sentinel-master:6379' }
      let(:sentinels) { [{ host: '10.0.0.1', port: '26379' }] }
      let(:mailbox) {
        build_mailbox(
          delivery_method: :sidekiq,
          delivery_options: {
            redis_url: redis_url,
            sentinels: sentinels
          }
        )
      }

      before { ::RedisClient::SentinelConfig.any_instance.stubs(:resolve_master).returns(RedisClient::Config.new(**sentinels.first)) }

      it 'client has same specified sentinel params' do
        expect(raw_client.config).to be_a RedisClient::SentinelConfig
        expect(raw_client.config.host).to eq('10.0.0.1')
        expect(raw_client.config.name).to eq('sentinel-master')
        expect(raw_client.config.password).to eq('mypassword')
        expect(raw_client.config.sentinels.map(&:server_url)).to eq(["redis://10.0.0.1:26379"])
      end
    end

  end
end
