require 'spec_helper'

describe MailRoom::CrashHandler do

  let(:error_message) { "oh noes!" }
  let(:error) { RuntimeError.new(error_message) }

  describe '#handle' do

    subject{ described_class.new(error: error, format: format) }

    context 'when given a json format' do
      let(:format) { 'json' }
      let(:fake_json) do
        { message: error_message }.to_json
      end

      it 'outputs the result of json to stdout' do
        subject.stubs(:json).returns(fake_json)

        expect{ subject.handle }.to output(/\"message\":\"#{error_message}\"/).to_stdout
      end
    end

    context 'when given a blank format' do
      let(:format) { "" }

      it 'raises an error as designed' do
        expect{ subject.handle }.to raise_error(error.class, error_message)
      end
    end

    context 'when given a nonexistent format' do
      let(:format) { "nonsense" }

      it 'raises an error as designed' do
        expect{ subject.handle }.to raise_error(error.class, error_message)
      end
    end

    context 'when given plain' do
      let(:format) { "plain" }

      it 'raises an error as designed (plain text, not structured)' do
        expect{ subject.handle }.to raise_error(error.class, error_message)
      end
    end
  end
end
