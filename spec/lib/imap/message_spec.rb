# frozen_string_literal:true

require 'spec_helper'
require 'securerandom'

describe MailRoom::IMAP::Message do
  let(:uid) { SecureRandom.hex }
  let(:body) { 'hello world' }
  let(:seqno) { 5 }

  subject { described_class.new(uid: uid, body: body, seqno: seqno) }

  describe '#initalize' do
    it 'initializes with required parameters' do
      subject

      expect(subject.uid).to eq(uid)
      expect(subject.body).to eq(body)
      expect(subject.seqno).to eq(seqno)
    end
  end

  describe '#==' do
    let(:dup) { described_class.new(uid: uid, body: body, seqno: seqno) }
    let(:base_msg) { MailRoom::Message.new(uid: uid, body: body) }

    it 'matches an equivalent message' do
      expect(dup == subject).to be true
    end

    it 'does not match a base message' do
      expect(subject == base_msg).to be false
      expect(base_msg == subject).to be false
    end
  end
end
