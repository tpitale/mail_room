# frozen_string_literal: true

require 'json'
require 'oauth2'

module MailRoom
  module MicrosoftGraph
    class Connection < MailRoom::Connection
      SCOPE = 'https://graph.microsoft.com/.default'
      NEXT_PAGE_KEY = '@odata.nextLink'
      DEFAULT_POLL_INTERVAL_S = 60

      TooManyRequestsError = Class.new(RuntimeError)

      attr_accessor :token, :throttled_count

      def initialize(mailbox)
        super

        reset
        setup
      end

      def wait
        return if stopped?

        process_mailbox

        @throttled_count = 0
        wait_for_new_messages
      rescue TooManyRequestsError => e
        @throttled_count += 1

        @mailbox.logger.warn({ context: @mailbox.context, action: 'Too many requests, backing off...', backoff_s: backoff_secs, error: e.message, error_backtrace: e.backtrace })

        backoff
      rescue IOError => e
        @mailbox.logger.warn({ context: @mailbox.context, action: 'Disconnected. Resetting...', error: e.message, error_backtrace: e.backtrace })

        reset
        setup
      end

      private

      def wait_for_new_messages
        sleep_while_running(poll_interval)
      end

      def backoff
        sleep_while_running(backoff_secs)
      end

      def backoff_secs
        [60 * 10, 2**throttled_count].min
      end

      # Unless wake up periodically, we won't notice that the thread was stopped
      # if we sleep the entire interval.
      def sleep_while_running(sleep_interval)
        sleep_interval.times do
          do_sleep(1)
          return if stopped?
        end
      end

      def do_sleep(interval)
        sleep(interval)
      end

      def reset
        @token = nil
        @throttled_count = 0
      end

      def setup
        @mailbox.logger.info({ context: @mailbox.context, action: 'Retrieving OAuth2 token...' })

        @token = client.client_credentials.get_token({ scope: SCOPE })
      end

      def client
        @client ||= OAuth2::Client.new(client_id, client_secret,
                                       site: 'https://login.microsoftonline.com',
                                       authorize_url: "/#{tenant_id}/oauth2/v2.0/authorize",
                                       token_url: "/#{tenant_id}/oauth2/v2.0/token",
                                       auth_scheme: :basic_auth)
      end

      def inbox_options
        mailbox.inbox_options
      end

      def tenant_id
        inbox_options[:tenant_id]
      end

      def client_id
        inbox_options[:client_id]
      end

      def client_secret
        inbox_options[:client_secret]
      end

      def poll_interval
        @poll_interval ||= begin
          interval = inbox_options[:poll_interval].to_i

          if interval.positive?
            interval
          else
            DEFAULT_POLL_INTERVAL_S
          end
        end
      end

      def process_mailbox
        return unless @new_message_handler

        @mailbox.logger.info({ context: @mailbox.context, action: 'Processing started' })

        new_messages.each do |msg|
          success = @new_message_handler.call(msg)
          handle_delivered(msg) if success
        end
      end

      def handle_delivered(msg)
        mark_as_read(msg)
        delete_message(msg) if @mailbox.delete_after_delivery
      end

      def delete_message(msg)
        token.delete(msg_url(msg.uid))
      end

      def mark_as_read(msg)
        token.patch(msg_url(msg.uid),
                    headers: { 'Content-Type' => 'application/json' },
                    body: { isRead: true }.to_json)
      end

      def new_messages
        messages_for_ids(new_message_ids)
      end

      # Yields a page of message IDs at a time
      def new_message_ids
        url = unread_messages_url

        Enumerator.new do |block|
          loop do
            messages, next_page_url = unread_messages(url: url)
            messages.each { |msg| block.yield msg }

            break unless next_page_url

            url = next_page_url
          end
        end
      end

      def unread_messages(url:)
        body = get(url)

        return [[], nil] unless body

        all_unread = body['value'].map { |msg| msg['id'] }
        to_deliver = all_unread.select { |uid| @mailbox.deliver?(uid) }
        @mailbox.logger.info({ context: @mailbox.context, action: 'Getting new messages',
                               unread: { count: all_unread.count, ids: all_unread },
                               to_be_delivered: { count: to_deliver.count, ids: to_deliver } })
        [to_deliver, body[NEXT_PAGE_KEY]]
      rescue TypeError, JSON::ParserError => e
        log_exception('Error parsing JSON response', e)
        [[], nil]
      end

      # Returns the JSON response
      def get(url)
        response = token.get(url, { raise_errors: false })

        # https://docs.microsoft.com/en-us/graph/errors
        case response.status
        when 509, 429
          raise TooManyRequestsError
        when 400..599
          raise OAuth2::Error, response
        end

        return unless response.body

        body = JSON.parse(response.body)

        raise TypeError, 'Response did not contain value hash' unless body.is_a?(Hash) && body.key?('value')

        body
      end

      def messages_for_ids(message_ids)
        message_ids.each_with_object([]) do |id, arr|
          response = token.get(rfc822_msg_url(id))

          arr << ::MailRoom::Message.new(uid: id, body: response.body)
        end
      end

      def base_url
        "https://graph.microsoft.com/v1.0/users/#{mailbox.email}/mailFolders/#{mailbox.name}/messages"
      end

      def unread_messages_url
        "#{base_url}?$filter=isRead eq false"
      end

      def msg_url(id)
        # Attempting to use the base_url fails with "The OData request is not supported"
        "https://graph.microsoft.com/v1.0/users/#{mailbox.email}/messages/#{id}"
      end

      def rfc822_msg_url(id)
        # Attempting to use the base_url fails with "The OData request is not supported"
        "#{msg_url(id)}/$value"
      end

      def log_exception(message, exception)
        @mailbox.logger.warn({ context: @mailbox.context, message: message, exception: exception.to_s })
      end
    end
  end
end
