require 'spec_helper'

describe MailRoom::IMAP::Connection do
  let(:imap) {stub}
  let(:mailbox) {build_mailbox(delete_after_delivery: true, expunge_deleted: true)}

  before :each do
    Net::IMAP.stubs(:new).returns(imap)
  end

  context "with imap set up" do
    let(:connection) {MailRoom::IMAP::Connection.new(mailbox)}
    let(:uid) { 1 }
    let(:seqno) { 8 }

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
      new_message = MailRoom::IMAP::Message.new(uid: uid, body: 'a message', seqno: seqno)

      connection.on_new_message do |message|
        expect(message).to eq(new_message)
        true
      end

      attr = { 'UID' => uid, 'RFC822' => new_message.body }
      fetch_data = Net::IMAP::FetchData.new(seqno, attr)

      imap.expects(:idle)
      imap.stubs(:uid_search).with(mailbox.search_command).returns([], [uid])
      imap.expects(:uid_fetch).with([uid], "RFC822").returns([fetch_data])
      mailbox.expects(:deliver?).with(uid).returns(true)
      imap.expects(:store).with(seqno, "+FLAGS", [Net::IMAP::DELETED])
      imap.expects(:expunge).once

      connection.wait
    end
  end
end
