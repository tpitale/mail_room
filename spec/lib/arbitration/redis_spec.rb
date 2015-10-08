require 'spec_helper'
require 'mail_room/arbitration/redis'

describe MailRoom::Arbitration::Redis do
  let(:mailbox) { 
    MailRoom::Mailbox.new(
      arbitration_options: {
        namespace: "mail_room"
      }
    ) 
  }
  let(:options) { described_class::Options.new(mailbox) }
  subject       { described_class.new(options) }

  # Private, but we don't care.
  let(:redis) { subject.send(:redis) }

  describe '#deliver?' do
    context "when called the first time" do
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
        subject.deliver?(123)
      end

      it "returns false" do
        expect(subject.deliver?(123)).to be_falsey
      end

      it "increments the delivered flag" do
        subject.deliver?(123)

        expect(redis.get("delivered:123")).to eq("2")
      end
    end

    context "when called for another uid" do
      before do
        subject.deliver?(123)
      end

      it "returns true" do
        expect(subject.deliver?(234)).to be_truthy
      end
    end
  end
end
