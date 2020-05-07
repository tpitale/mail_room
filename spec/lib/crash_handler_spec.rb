require 'spec_helper'

describe MailRoom::CrashHandler do

  let(:error_message) { "oh noes!" }
  let(:error) { RuntimeError.new(error_message) }
  let(:stdout) { StringIO.new }

  describe '#handle' do

    subject{ described_class.new(stdout).handle(error, format) }

    context 'when given a json format' do
      let(:format) { 'json' }

      it 'writes a json message to stdout' do
        subject
        stdout.rewind
        output = stdout.read

        expect(output).to end_with("\n")
        expect(JSON.parse(output)['message']).to eq(error_message)
      end
    end

    context 'when given a blank format' do
      let(:format) { "" }

      it 'raises an error as designed' do
        expect{ subject }.to raise_error(error.class, error_message)
      end
    end

    context 'when given a nonexistent format' do
      let(:format) { "nonsense" }

      it 'raises an error as designed' do
        expect{ subject }.to raise_error(error.class, error_message)
      end
    end
  end
end
