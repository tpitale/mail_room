require 'spec_helper'

describe MailRoom::Mailbox do
  let(:sample_message) { MailRoom::Message.new(uid: 123, body: 'a message') }

  context 'with IMAP configuration' do
    subject { build_mailbox }

    describe '#imap?' do
      it 'configured as an IMAP inbox' do
        expect(subject.imap?).to be true
        expect(subject.microsoft_graph?).to be false
      end
    end
  end

  describe "#deliver" do
    context "with arbitration_method of noop" do
      it 'arbitrates with a Noop instance' do
        mailbox = build_mailbox({:arbitration_method => 'noop'})
        noop = stub(:deliver?)
        MailRoom::Arbitration['noop'].stubs(:new => noop)

        uid = 123

        noop.expects(:deliver?).with(uid)

        mailbox.deliver?(uid)
      end
    end

    context "with arbitration_method of redis" do
      it 'arbitrates with a Redis instance' do
        mailbox = build_mailbox({:arbitration_method => 'redis'})
        redis = stub(:deliver?)
        MailRoom::Arbitration['redis'].stubs(:new => redis)
        uid = 123
        redis.expects(:deliver?).with(uid)

        mailbox.deliver?(uid)
      end
    end

    context "with delivery_method of noop" do
      it 'delivers with a Noop instance' do
        mailbox = build_mailbox({:delivery_method => 'noop'})
        noop = stub(:deliver)
        MailRoom::Delivery['noop'].stubs(:new => noop)

        noop.expects(:deliver).with(sample_message.body)

        mailbox.deliver(sample_message)
      end
    end

    context "with delivery_method of logger" do
      it 'delivers with a Logger instance' do
        mailbox = build_mailbox({:delivery_method => 'logger'})
        logger = stub(:deliver)
        MailRoom::Delivery['logger'].stubs(:new => logger)

        logger.expects(:deliver).with(sample_message.body)

        mailbox.deliver(sample_message)
      end
    end

    context "with delivery_method of postback" do
      it 'delivers with a Postback instance' do
        mailbox = build_mailbox({:delivery_method => 'postback'})
        postback = stub(:deliver)
        MailRoom::Delivery['postback'].stubs(:new => postback)

        postback.expects(:deliver).with(sample_message.body)

        mailbox.deliver(sample_message)
      end
    end

    context "with delivery_method of letter_opener" do
      it 'delivers with a LetterOpener instance' do
        mailbox = build_mailbox({:delivery_method => 'letter_opener'})
        letter_opener = stub(:deliver)
        MailRoom::Delivery['letter_opener'].stubs(:new => letter_opener)

        letter_opener.expects(:deliver).with(sample_message.body)

        mailbox.deliver(sample_message)
      end
    end

    context "without an RFC822 attribute" do
      it "doesn't deliver the message" do
        mailbox = build_mailbox({ name: "magic mailbox", delivery_method: 'noop' })
        noop = stub(:deliver)
        MailRoom::Delivery['noop'].stubs(:new => noop)
        noop.expects(:deliver).never

        mailbox.deliver(MailRoom::Message.new(uid: 1234, body: nil))
      end
    end

    context "with ssl options hash" do
      it 'replaces verify mode with constant' do
        mailbox = build_mailbox({:ssl => {:verify_mode => :none}})

        expect(mailbox.ssl_options).to eq({:verify_mode => OpenSSL::SSL::VERIFY_NONE})
      end
    end

    context 'structured logger setup' do
      it 'sets up the logger correctly and does not error' do
        mailbox = build_mailbox({ name: "magic mailbox", logger: { log_path: '/dev/null' } })

        expect{ mailbox.logger.info(message: "asdf") }.not_to raise_error
      end

      it 'accepts stdout symbol to mean STDOUT' do
        mailbox = build_mailbox({ name: "magic mailbox", logger: { log_path: :stdout } })

        expect{ mailbox.logger.info(message: "asdf") }.not_to raise_error
      end

      it 'sets up the noop logger correctly and does not error' do
        mailbox = build_mailbox({ name: "magic mailbox" })

        expect{ mailbox.logger.info(message: "asdf") }.not_to raise_error
      end
    end
  end

  describe "#validate!" do
    context "with missing configuration" do
      it 'raises an error' do
        expect { build_mailbox({:name => nil}) }.to raise_error(MailRoom::ConfigurationError)
        expect { build_mailbox({:host => nil}) }.to raise_error(MailRoom::ConfigurationError)
      end
    end

    context "with Microsoft Graph configuration" do
      let(:options) do
        {
          arbitration_method: 'redis',
        }.merge(REQUIRED_MICROSOFT_GRAPH_DEFAULTS)
      end

      subject { build_mailbox(options) }

      def delete_inbox_option(key)
        options[:inbox_options] = options[:inbox_options].dup.delete(key)
      end

      it 'allows password omission' do
        expect { subject }.not_to raise_error
      end

      it 'configured as a Microsoft Graph inbox' do
        expect(subject.imap?).to be false
        expect(subject.microsoft_graph?).to be true
      end

      it 'raises an error when the inbox options are not present' do
        options.delete(:inbox_options)

        expect { subject }.to raise_error(MailRoom::ConfigurationError)
      end

      %i[tenant_id client_id client_secret].each do |item|
        it "raises an error when the #{item} is not present" do
          delete_inbox_option(item)

          expect { subject }.to raise_error(MailRoom::ConfigurationError)
        end
      end
    end
  end
end
