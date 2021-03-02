require 'spec_helper'

describe MailRoom::MailboxWatcher do
  let(:mailbox) {build_mailbox}

  describe '#running?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(mailbox)
      expect(watcher.running?).to eq(false)
    end
  end

  describe '#run' do
    let(:imap) {stub(:login => true, :select => true)}
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    before :each do
      Net::IMAP.stubs(:new).returns(imap) # prevent connection
    end

    it 'loops over wait while running' do
      connection = MailRoom::Connection::IMAP.new(mailbox)

      MailRoom::Connection::IMAP.stubs(:new).returns(connection)

      watcher.expects(:running?).twice.returns(true, false)
      connection.expects(:wait).once
      connection.expects(:on_new_message).once

      watcher.run
      watcher.watching_thread.join # wait for finishing run
    end
  end

  describe '#quit' do
    let(:imap) {stub(:login => true, :select => true)}
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    before :each do
      Net::IMAP.stubs(:new).returns(imap) # prevent connection
    end

    it 'closes and waits for the connection' do
      connection = MailRoom::Connection::IMAP.new(mailbox)
      connection.stubs(:wait)
      connection.stubs(:quit)

      MailRoom::Connection::IMAP.stubs(:new).returns(connection)

      watcher.run

      expect(watcher.running?).to eq(true)

      connection.expects(:quit)

      watcher.quit

      expect(watcher.running?).to eq(false)
    end
  end
end
