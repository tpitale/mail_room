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
      connection = MailRoom::Connection.new(mailbox)
      connection.stubs(:on_new_message)
      connection.stubs(:wait)

      MailRoom::Connection.stubs(:new).returns(connection)

      watcher.stubs(:running?).returns(true).then.returns(false)

      watcher.run
      watcher.watching_thread.join # wait for finishing run

      expect(watcher).to have_received(:running?).times(2)
      expect(connection).to have_received(:wait).once
      expect(connection).to have_received(:on_new_message).once
    end
  end

  describe '#quit' do
    let(:imap) {stub(:login => true, :select => true)}
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    before :each do
      Net::IMAP.stubs(:new).returns(imap) # prevent connection
    end

    it 'closes and waits for the connection' do
      connection = MailRoom::Connection.new(mailbox)
      connection.stubs(:wait)
      connection.stubs(:quit)

      MailRoom::Connection.stubs(:new).returns(connection)

      watcher.run

      expect(watcher.running?).to eq(true)

      watcher.quit

      expect(connection).to have_received(:quit)
      expect(watcher.running?).to eq(false)
    end
  end
end
