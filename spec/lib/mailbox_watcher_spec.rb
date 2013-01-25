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
    it 'handles any response with a name of EXISTS and stops idling' do
      response = stub(:name => 'EXISTS')

      imap = stub
      imap.stubs(:idle).yields(response)
      imap.stubs(:idle_done)

      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.stubs(:logged_in?).returns(true)
      watcher.stubs(:imap).returns(imap)

      watcher.idle

      imap.should have_received(:idle)
      imap.should have_received(:idle_done)
    end

    it 'returns if not logged in' do
      imap = stub

      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.stubs(:logged_in?).returns(false)
      watcher.stubs(:imap).returns(imap)

      watcher.idle

      imap.should have_received(:idle).never
    end

    it 'does not finish idling unless it gets EXISTS' do
      response = stub(:name => 'DESTROY')

      imap = stub
      imap.stubs(:idle).yields(response)
      imap.stubs(:idle_done)

      watcher = MailRoom::MailboxWatcher.new(nil)
      watcher.stubs(:logged_in?).returns(true)
      watcher.stubs(:imap).returns(imap)

      watcher.idle

      imap.should have_received(:idle)
      imap.should have_received(:idle_done).never
    end
  end

  describe '#stop_idling' do
    
  end
end
