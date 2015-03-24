require 'spec_helper'

describe MailRoom::MailboxHandler do
  describe 'process mailbox' do
    let(:imap) {stub}
    let(:mailbox) {MailRoom::Mailbox.new}

    it 'fetches and delivers all new messages from ids' do
      imap.stubs(:search).returns([1,2])
      imap.stubs(:fetch).returns(['message1', 'message2'])
      mailbox.stubs(:deliver)

      handler = MailRoom::MailboxHandler.new(mailbox, imap)
      handler.process

      imap.should have_received(:search).with('UNSEEN')
      imap.should have_received(:fetch).with([1,2], 'RFC822')
      mailbox.should have_received(:deliver).with('message1')
      mailbox.should have_received(:deliver).with('message2')
    end

    it 'returns no messages if there are no ids' do
      imap.stubs(:search).returns([])
      imap.stubs(:fetch)
      mailbox.search_command = 'NEW'
      mailbox.stubs(:deliver)

      handler = MailRoom::MailboxHandler.new(mailbox, imap)
      handler.process

      imap.should have_received(:search).with('NEW')
      imap.should have_received(:fetch).never
      mailbox.should have_received(:deliver).never
    end
  end
end