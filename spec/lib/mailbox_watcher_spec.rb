require 'spec_helper'

describe MailRoom::MailboxWatcher do
  let(:mailbox) {MailRoom::Mailbox.new}

  describe '#running?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(mailbox)
      expect(watcher.running?).to eq(false)
    end
  end

  describe '#logged_in?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(mailbox)
      expect(watcher.logged_in?).to eq(false)
    end
  end

  describe '#idling?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(mailbox)
      expect(watcher.idling?).to eq(false)
    end
  end

  describe '#imap' do
    it 'builds a new Net::IMAP object' do
      MailRoom::IMAP.stubs(:new).returns('imap')

      expect(MailRoom::MailboxWatcher.new(mailbox).imap).to eq('imap')

      expect(MailRoom::IMAP).to have_received(:new).with('imap.gmail.com', :port => 993, :ssl => true)
    end
  end

  describe '#setup' do
    let(:imap) {stub(:login => true, :select => true)}

    let(:mailbox) {
      MailRoom::Mailbox.new(:email => 'user1@gmail.com', :password => 'password', :name => 'inbox')
    }

    let(:watcher) {
      MailRoom::MailboxWatcher.new(mailbox)
    }

    it 'logs in and sets the mailbox to watch' do
      watcher.stubs(:imap).returns(imap)

      watcher.setup

      expect(imap).to have_received(:login).with('user1@gmail.com', 'password')
      expect(watcher.logged_in?).to eq(true)
      expect(imap).to have_received(:select).with('inbox')
    end

    context 'with start_tls configured as true' do
      before(:each) do
        mailbox.start_tls = true
        imap.stubs(:starttls)
        watcher.stubs(:imap).returns(imap)
      end

      it 'sets up tls session on imap setup' do
        watcher.setup

        expect(imap).to have_received(:starttls)
      end
    end
  end

  describe '#idle' do
    let(:imap) {stub}
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    before :each do
      watcher.stubs(:imap).returns(imap)
    end

    it 'returns if not logged in' do
      watcher.stubs(:logged_in?).returns(false)

      watcher.idle

      expect(imap).to have_received(:idle).never
    end

    context "when logged in" do
      before :each do
        imap.stubs(:idle_done)

        watcher.stubs(:logged_in?).returns(true)
      end

      it 'handles any response with a name of EXISTS and stops idling' do
        response = stub(:name => 'EXISTS')
        imap.stubs(:idle).yields(response)

        watcher.idle

        expect(imap).to have_received(:idle)
        expect(imap).to have_received(:idle_done)
      end

      it 'does not finish idling when response is not EXISTS' do
        response = stub(:name => 'DESTROY')
        imap.stubs(:idle).yields(response)

        watcher.idle

        expect(imap).to have_received(:idle)
        expect(imap).to have_received(:idle_done).never
      end
    end
  end

  describe 'process_mailbox' do
    let(:imap) {stub}
    let(:mailbox) {MailRoom::Mailbox.new}
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    it 'builds a new mailbox handler if none exists' do
      MailRoom::MailboxHandler.stubs(:new).returns(stub(:process))
      watcher.stubs(:imap).returns(imap)

      watcher.process_mailbox

      expect(MailRoom::MailboxHandler).to have_received(:new).with(mailbox, imap)
    end

    it 'processes with the handler' do
      handler = stub(:process)
      watcher.stubs(:handler).returns(handler)

      watcher.process_mailbox

      expect(handler).to have_received(:process)
    end
  end

  describe '#stop_idling' do
    let(:imap) {stub}
    let(:idling_thread) {stub(:abort_on_exception=)}
    let(:watcher) {MailRoom::MailboxWatcher.new(nil)}

    before :each do
      watcher.stubs(:imap).returns(imap)
      watcher.stubs(:idling_thread).returns(idling_thread)
    end

    it "returns unless imap is idling" do
      imap.stubs(:idle_done)
      idling_thread.stubs(:join)
      watcher.stubs(:idling?).returns(false)

      watcher.stop_idling

      expect(imap).to have_received(:idle_done).never
      expect(idling_thread).to have_received(:join).never
    end

    context "when idling" do
      before :each do
        imap.stubs(:idle_done)
        idling_thread.stubs(:join)
        watcher.stubs(:idling?).returns(true)
      end

      it 'stops the idle' do
        watcher.stop_idling
        expect(imap).to have_received(:idle_done)
      end

      it 'waits on the idling_thread to finish' do
        watcher.stop_idling
        expect(idling_thread).to have_received(:join)
      end
    end
  end

  describe '#run' do
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    before :each do
      Net::IMAP.stubs(:new).returns(stub)
      Thread.stubs(:start).yields.returns(stub(:abort_on_exception=))
      watcher.stubs(:setup)
      watcher.handler.stubs(:process)
    end

    it 'sets up' do
      watcher.stubs(:running?).returns(false)

      watcher.run

      expect(watcher).to have_received(:setup)
    end

    it 'starts a thread for idling' do
      watcher.stubs(:running?).returns(false)

      watcher.run

      expect(Thread).to have_received(:start)
    end

    it 'loops while running' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)

      watcher.run

      expect(watcher).to have_received(:running?).times(2)
    end

    it 'idles' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)

      watcher.run

      expect(watcher).to have_received(:idle).once
    end

    it 'processes messages' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)

      watcher.run

      expect(watcher.handler).to have_received(:process).times(2)
    end
  end

  describe '#quit' do
    let(:watcher) {MailRoom::MailboxWatcher.new(mailbox)}

    it 'stops idling' do
      watcher.stubs(:stop_idling)

      watcher.quit

      expect(watcher).to have_received(:stop_idling)
    end
  end
end
