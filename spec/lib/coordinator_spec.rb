require 'spec_helper'

describe MailRoom::Coordinator do
  describe '#initialize' do
    it 'builds a watcher for each mailbox' do
      MailRoom::MailboxWatcher.expects(:new).with('mailbox1').returns('watcher1')
      MailRoom::MailboxWatcher.expects(:new).with('mailbox2').returns('watcher2')

      coordinator = MailRoom::Coordinator.new(['mailbox1', 'mailbox2'])

      expect(coordinator.watchers).to eq(['watcher1', 'watcher2'])
    end

    it 'makes no watchers when mailboxes is empty' do
      coordinator = MailRoom::Coordinator.new([])
      expect(coordinator.watchers).to eq([])
    end
  end

  describe '#run' do
    it 'runs each watcher' do
      watcher = stub
      watcher.stubs(:run)
      watcher.stubs(:quit)
      MailRoom::MailboxWatcher.stubs(:new).returns(watcher)
      coordinator = MailRoom::Coordinator.new(['mailbox1'])
      coordinator.stubs(:sleep_while_running)
      watcher.expects(:run)
      watcher.expects(:quit)

      coordinator.run
    end
    
    it 'should go to sleep after running watchers' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.stubs(:running=)
      coordinator.stubs(:running?).returns(false)
      coordinator.expects(:running=).with(true)
      coordinator.expects(:running?)

      coordinator.run
    end

    it 'should set attribute running to true' do
      coordinator = MailRoom::Coordinator.new([])
      coordinator.stubs(:sleep_while_running)
      coordinator.run

      expect(coordinator.running).to eq(true)
    end
  end

  describe '#quit' do
    it 'quits each watcher' do
      watcher = stub(:quit)
      MailRoom::MailboxWatcher.stubs(:new).returns(watcher)
      coordinator = MailRoom::Coordinator.new(['mailbox1'])
      watcher.expects(:quit)

      coordinator.quit
    end
  end
end
