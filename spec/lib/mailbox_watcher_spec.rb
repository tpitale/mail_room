require 'spec_helper'

describe MailRoom::MailboxWatcher do
  describe '#running?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.running?.should eq(false)
    end
  end

  describe '#logged_in?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.logged_in?.should eq(false)
    end
  end

  describe '#idling?' do
    it 'is false by default' do
      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.idling?.should eq(false)
    end
  end

  describe '#imap' do
    it 'builds a new Net::IMAP object' do
      Net::IMAP.stubs(:new).returns('imap')

      MailRoom::MailboxWatcher.new(nil).imap.should eq('imap')

      Net::IMAP.should have_received(:new).with('imap.gmail.com', :port => 993, :ssl => true)
    end
    
    it 'builds a new Net::IMAP object with server param' do
      Net::IMAP.stubs(:new).returns('imap')
      mailbox = stub(:server => 'outlook.office365.com', :email => 'drrosen@rosen.edu', :password => 'password', :name => 'inbox')
      MailRoom::MailboxWatcher.new(mailbox).imap.should eq('imap')

       Net::IMAP.should have_received(:new).with('outlook.office365.com', :port => 993, :ssl => true)
    end
  end

  describe '#setup' do
    it 'logs in and sets the mailbox to watch' do
      imap = stub(:login => true, :select => true)
      mailbox = stub(:email => 'user1@gmail.com', :password => 'password', :name => 'inbox')
      watcher = MailRoom::MailboxWatcher.new(mailbox)
      watcher.stubs(:imap).returns(imap)

      watcher.setup

      imap.should have_received(:login).with('user1@gmail.com', 'password')
      watcher.logged_in?.should eq(true)
      imap.should have_received(:select).with('inbox')
    end
  end

  describe '#idle' do
    let(:imap) {stub}
    let(:watcher) {MailRoom::MailboxWatcher.new(nil)}

    before :each do
      watcher.stubs(:imap).returns(imap)
    end

    it 'returns if not logged in' do
      watcher.stubs(:logged_in?).returns(false)

      watcher.idle

      imap.should have_received(:idle).never
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

        imap.should have_received(:idle)
        imap.should have_received(:idle_done)
      end

      it 'does not finish idling when response is not EXISTS' do
        response = stub(:name => 'DESTROY')
        imap.stubs(:idle).yields(response)

        watcher.idle

        imap.should have_received(:idle)
        imap.should have_received(:idle_done).never
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

      MailRoom::MailboxHandler.should have_received(:new).with(mailbox, imap)
    end

    it 'processes with the handler' do
      handler = stub(:process)
      watcher.stubs(:handler).returns(handler)

      watcher.process_mailbox

      handler.should have_received(:process)
    end
  end

  describe '#stop_idling' do
    let(:imap) {stub}
    let(:idling_thread) {stub}
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

      imap.should have_received(:idle_done).never
      idling_thread.should have_received(:join).never
    end

    context "when idling" do
      before :each do
        imap.stubs(:idle_done)
        idling_thread.stubs(:join)
        watcher.stubs(:idling?).returns(true)
      end

      it 'stops the idle' do
        watcher.stop_idling
        imap.should have_received(:idle_done)
      end

      it 'waits on the idling_thread to finish' do
        watcher.stop_idling
        idling_thread.should have_received(:join)
      end
    end
  end

  describe '#run' do
    let(:watcher) {MailRoom::MailboxWatcher.new(nil)}

    before :each do
      Thread.stubs(:start).yields
      watcher.stubs(:setup)
    end

    it 'sets up' do
      watcher.stubs(:running?).returns(false)

      watcher.run

      watcher.should have_received(:setup)
    end

    it 'starts a thread for idling' do
      watcher.stubs(:running?).returns(false)

      watcher.run

      Thread.should have_received(:start)
    end

    it 'loops while running' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)
      watcher.stubs(:process_mailbox)

      watcher.run

      watcher.should have_received(:running?).times(2)
    end

    it 'idles' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)
      watcher.stubs(:process_mailbox)

      watcher.run

      watcher.should have_received(:idle).once
    end

    it 'processes messages' do
      watcher.stubs(:running?).returns(true, false)

      watcher.stubs(:idle)
      watcher.stubs(:process_mailbox)

      watcher.run

      watcher.should have_received(:process_mailbox).once
    end
  end

  describe '#quit' do
    let(:watcher) {MailRoom::MailboxWatcher.new(nil)}

    it 'stops idling' do
      watcher.stubs(:stop_idling)

      watcher.quit

      watcher.should have_received(:stop_idling)
    end
  end
end
