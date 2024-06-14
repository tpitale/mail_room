# frozen_string_literal: true

require 'spec_helper'

describe MailRoom::HealthCheck::Http do
  let(:address) { '127.0.0.1' }
  let(:port) { 8000 }
  let(:params) { { address: address, port: port } }
  subject { described_class.new(params) }

  describe '#initialize' do
    context 'with valid parameters' do
      it 'validates successfully' do
        expect(subject).to be_a(described_class)
      end
    end

    context 'with invalid address' do
      let(:address) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error('No health check address specified')
      end
    end

    context 'with invalid port' do
      let(:port) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error('Health check port 0 is invalid')
      end
    end
  end

  describe '#run' do
    it 'sets running to true' do
      server = stub(start: true)
      subject.stubs(:create_server).returns(server)

      subject.run

      expect(subject.running).to be true
    end
  end

  describe '#quit' do
    it 'sets running to false' do
      server = stub(start: true, shutdown: true)
      subject.stubs(:create_server).returns(server)

      subject.run
      subject.quit

      expect(subject.running).to be false
    end
  end
end
