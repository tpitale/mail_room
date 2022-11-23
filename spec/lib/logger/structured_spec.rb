require 'spec_helper'

describe MailRoom::Logger::Structured do

  subject { described_class.new $stdout }

  let!(:now) { Time.now }
  let(:timestamp) { now.to_datetime.iso8601(3) }
  let(:message) { { action: 'exciting development', message: 'testing 123' } }

  before do
    Time.stubs(:now).returns(now)
  end

  [:debug, :info, :warn, :error, :fatal].each do |level|
    it "logs #{level}" do
      expect { subject.send(level, message) }.to output(json_matching(level.to_s.upcase, message)).to_stdout_from_any_process
    end
  end

  it 'logs unknown' do
    expect { subject.unknown(message) }.to output(json_matching("ANY", message)).to_stdout_from_any_process
  end

  it 'only accepts hashes' do
    expect { subject.unknown("just a string!") }.to raise_error(ArgumentError, /must be a Hash/)
  end

  context 'logging a hash as a message' do
    it 'merges the contents' do
      input = {
          additional_field: "some value"
      }
      expected = {
          severity: 'DEBUG',
          time: timestamp,
          additional_field: "some value"
      }

      expect { subject.debug(input) }.to output(as_regex(expected)).to_stdout_from_any_process
    end
  end

  describe '#format_message' do
    shared_examples 'timestamp formatting' do
      it 'outputs ISO8601 timestamps' do
        data = JSON.parse(subject.format_message('debug', input_timestamp, 'test', { message: 'hello' } ))

        expect(data['time']).to eq(expected_timestamp)
      end
    end

    context 'with no timestamp' do
      let(:input_timestamp) { nil }
      let(:expected_timestamp) { timestamp }

      it_behaves_like 'timestamp formatting'
    end

    context 'with DateTime' do
      let(:input_timestamp) { now.to_datetime }
      let(:expected_timestamp) { timestamp }

      it_behaves_like 'timestamp formatting'
    end

    context 'with string' do
      let(:input_timestamp) { now.to_s }
      let(:expected_timestamp) { input_timestamp }

      it_behaves_like 'timestamp formatting'
    end
  end

  def json_matching(level, message)
    contents = {
        severity: level,
        time: timestamp
    }.merge(message)

    as_regex(contents)
  end

  def as_regex(contents)
    /#{Regexp.quote(contents.to_json)}/
  end
end
