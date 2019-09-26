require 'spec_helper'

describe MailRoom::Connection do
  let(:imap) {stub}
  let(:mailbox) {build_mailbox(delete_after_delivery: true)}

  before :each do
    Net::IMAP.stubs(:new).returns(imap)
  end

  context "with imap set up" do
    let(:connection) {MailRoom::Connection.new(mailbox)}

    before :each do
      imap.stubs(:starttls)
      imap.stubs(:login)
      imap.stubs(:select)
    end

    it "is logged in" do
      expect(connection.logged_in?).to eq(true)
    end

    it "is not idling" do
      expect(connection.idling?).to eq(false)
    end

    it "is not disconnected" do
      imap.stubs(:disconnected?).returns(false)

      expect(connection.disconnected?).to eq(false)
    end

    it "is ready to idle" do
      expect(connection.ready_to_idle?).to eq(true)
    end

    it "waits for a message to process" do
      new_message = 'a message'
      new_message.stubs(:seqno).returns(8)

      connection.on_new_message do |message|
        expect(message).to eq(new_message)
        true
      end

      mailbox.stubs(:deliver?).returns(true)

      imap.stubs(:idle)
      imap.stubs(:uid_search).returns([]).then.returns([1])
      imap.stubs(:uid_fetch).returns([new_message])
      imap.stubs(:store)

      connection.wait

      expect(imap).to have_received(:idle)
      expect(imap).to have_received(:uid_search).with(mailbox.search_command).twice
      expect(imap).to have_received(:uid_fetch).with([1], "RFC822")
      expect(mailbox).to have_received(:deliver?).with(1)
      expect(imap).to have_received(:store).with(8, "+FLAGS", [Net::IMAP::DELETED])
    end
  end
end
