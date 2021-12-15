# frozen_string_literal: true

require 'spec_helper'

describe MailRoom::HealthCheck::Nop do
  subject { described_class.new }

  describe '#initialize' do
    it 'initializes successfully' do
      expect(subject).to be_a(described_class)
    end
  end

  describe '#run' do
    it 'does nothing' do
      subject.run
    end
  end

  describe '#quit' do
    it 'does nothing' do
      subject.quit
    end
  end

  describe '#validate!' do
    it 'returns nil' do
      expect(subject.validate!).to be_nil
    end
  end
end
