require 'spec_helper'
require 'mail_room/delivery/sidekiq'

describe MailRoom::Delivery::Sidekiq do
  subject { described_class.new(options) }
  let(:redis) { subject.send(:client) }
  let(:raw_client) { redis._client }
  let(:options) { MailRoom::Delivery::Sidekiq::Options.new(mailbox) }
  let(:redis5) { Gem::Version.new(Redis::VERSION) >= Gem::Version.new('5.0') }
  let(:server_url) do
    if redis5
      raw_client.config.server_url
    else
      raw_client.options[:url]
    end
  end

  describe '#options' do
    let(:redis_url) { 'redis://localhost' }
    let(:redis_options) { { redis_url: redis_url } }

    context 'when only redis_url is specified' do
      let(:mailbox) {
        build_mailbox(
          delivery_method: :sidekiq,
          delivery_options: redis_options
        )
      }

      context 'with simple redis url' do
        let(:expected_url) { redis5 ? "#{redis_url}:6379/0" : redis_url }

        it 'client has same specified redis_url' do
          expect(raw_client.server_url).to eq(expected_url)
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
        let(:expected_url) { redis5 ? "#{redis_url}:6379/4" : redis_url }

        before do
          redis_options[:redis_db] = 4
        end

        it 'client has correct redis_url' do
          expect(raw_client.server_url).to eq(expected_url)
        end

        it 'connection has correct values' do
          expect(redis.connection[:host]).to eq('localhost')
          expect(redis.connection[:db]).to eq(4)
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

      it 'client has same specified sentinel params' do
        if redis5
          expect(raw_client.config.password).to eq('mypassword')
          client_sentinels = raw_client.config.sentinels
          expect(client_sentinels.length).to eq(sentinels.length)
          expect(client_sentinels[0].host).to eq('10.0.0.1')
          expect(client_sentinels[0].port).to eq(26379) # rubocop:disable Style/NumericLiterals
        else
          expect(raw_client.options[:host]).to eq('sentinel-master')
          expect(raw_client.options[:password]).to eq('mypassword')
          expect(raw_client.options[:sentinels]).to eq(sentinels)
        end
      end
    end
  end
end
