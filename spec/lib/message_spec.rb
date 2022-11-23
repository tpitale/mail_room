# frozen_string_literal:true

require 'spec_helper'
require 'securerandom'

describe MailRoom::Message do
  let(:uid) { SecureRandom.hex }
  let(:body) { 'hello world' }

  subject { described_class.new(uid: uid, body: body) }

  describe '#initalize' do
    it 'initializes with required parameters' do
      subject

      expect(subject.uid).to eq(uid)
      expect(subject.body).to eq(body)
    end
  end

  describe '#==' do
    let(:dup) { described_class.new(uid: uid, body: body) }

    it 'matches an equivalent message' do
      expect(dup == subject).to be true
    end

    it 'does not match a message with a different UID' do
      msg = described_class.new(uid: '12345', body: body)

      expect(subject == msg).to be false
      expect(msg == subject).to be false
    end
  end
end
