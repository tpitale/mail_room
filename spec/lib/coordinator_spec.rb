require 'spec_helper'

describe MailRoom::Coordinator do
  describe '#initialize' do
    it 'builds a watcher for each mailbox' do
      MailRoom::MailboxWatcher.stubs(:new).returns('watcher1', 'watcher2')

      coordinator = MailRoom::Coordinator.new(['mailbox1', 'mailbox2'])

      coordinator.watchers.should eq(['watcher1', 'watcher2'])

      MailRoom::MailboxWatcher.should have_received(:new).with('mailbox1')
      MailRoom::MailboxWatcher.should have_received(:new).with('mailbox2')
    end

    it 'makes no watchers when mailboxes is empty' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.watchers.should eq([])
    end
  end

  describe '#run' do
    it 'runs each watcher' do
      watcher = stub(:run)
      MailRoom::MailboxWatcher.stubs(:new).returns(watcher)
      coordinator = MailRoom::Coordinator.new(['mailbox1'])
      coordinator.stubs(:sleep_while_running)
      coordinator.run
      watcher.should have_received(:run)
    end
    
    it 'should go to sleep after running watchers' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.stubs(:sleep_while_running)
      coordinator.run
      coordinator.should have_received(:sleep_while_running)
    end

    it 'should set attribute running to true' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.stubs(:sleep_while_running)
      coordinator.run
      coordinator.running.should eq(true)
    end
  end

  describe '#sleep_while_running' do
    it 'should check the running state' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.stubs(:running?).returns(false)
      coordinator.sleep_while_running
      coordinator.should have_received(:running?)
    end
  end

  describe '#quit' do
    it 'quits each watcher' do
      watcher = stub(:quit)
      MailRoom::MailboxWatcher.stubs(:new).returns(watcher)
      coordinator = MailRoom::Coordinator.new(['mailbox1'])
      coordinator.quit
      watcher.should have_received(:quit)
    end
    
    it 'should set state attribute running to false' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.quit
      coordinator.running.should eq(false)
    end
  end
end
