require 'spec_helper'

describe MailRoom::MailboxWatcher do
  context 'with IMAP configured' do
    let(:mailbox) {build_mailbox}

    describe '#running?' do
      it 'is false by default' do
        watcher = MailRoom::MailboxWatcher.new(mailbox)
        expect(watcher.running?).to eq(false)
      end
    end

    describe '#run' do
      let(:imap) {stub(login: true, select: true)}
      let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

      before :each do
        Net::IMAP.stubs(:new).returns(imap) # prevent connection
      end

      it 'loops over wait while running' do
        connection = MailRoom::IMAP::Connection.new(mailbox)

        MailRoom::IMAP::Connection.stubs(:new).returns(connection)

        watcher.expects(:running?).twice.returns(true, false)
        connection.expects(:wait).once
        connection.expects(:on_new_message).once

        watcher.run
        watcher.watching_thread.join # wait for finishing run
      end
    end

    describe '#quit' do
      let(:imap) {stub(login: true, select: true)}
      let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

      before :each do
        Net::IMAP.stubs(:new).returns(imap) # prevent connection
      end

      it 'closes and waits for the connection' do
        connection = MailRoom::IMAP::Connection.new(mailbox)
        connection.stubs(:wait)
        connection.stubs(:quit)

        MailRoom::IMAP::Connection.stubs(:new).returns(connection)

        watcher.run

        expect(watcher.running?).to eq(true)

        connection.expects(:quit)

        watcher.quit

        expect(watcher.running?).to eq(false)
      end
    end
  end

  context 'with Microsoft Graph configured' do
    let(:mailbox) { build_mailbox(REQUIRED_MICROSOFT_GRAPH_DEFAULTS) }

    subject { described_class.new(mailbox) }

    it 'initializes a Microsoft Graph connection' do
      connection = stub(on_new_message: nil)

      MailRoom::MicrosoftGraph::Connection.stubs(:new).returns(connection)

      expect(subject.send(:connection)).to eq(connection)
    end
  end
end
