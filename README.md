# mail_room #

mail_room is a configuration based process that will listen for incoming
e-mail and execute a delivery method when a new message is
received. mail_room supports the following methods for receiving e-mail:

* IMAP
* [Microsoft Graph API](https://docs.microsoft.com/en-us/graph/api/resources/mail-api-overview?view=graph-rest-1.0)

Examples of delivery methods include:

* POST to a delivery URL (Postback)
* Queue a job to Sidekiq or Que for later processing (Sidekiq or Que)
* Log the message or open with LetterOpener (Logger or LetterOpener)

[![Build Status](https://travis-ci.org/tpitale/mail_room.png?branch=master)](https://travis-ci.org/tpitale/mail_room)
[![Code Climate](https://codeclimate.com/github/tpitale/mail_room/badges/gpa.svg)](https://codeclimate.com/github/tpitale/mail_room)

## Installation ##

Add this line to your application's Gemfile:

    gem 'mail_room'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mail_room

You will also need to install `faraday` or `letter_opener` if you use the `postback` or `letter_opener` delivery methods, respectively.

## Usage ##

    mail_room -c /path/to/config.yml

**Note:** To ignore missing config file or missing `mailboxes` key, use `-q` or `--quiet`

## Configuration ##

```yaml
---
:mailboxes:
  -
    :email: "user1@gmail.com"
    :password: "password"
    :name: "inbox"
    :search_command: 'NEW'
    :logger:
      :log_path: /path/to/logfile/for/mailroom
    :delivery_options:
      :delivery_url: "http://localhost:3000/inbox"
      :delivery_token: "abcdefg"
      :content_type: "text/plain"

  -
    :email: "user2@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: postback
    :delivery_options:
      :delivery_url: "http://localhost:3000/inbox"
      :delivery_token: "abcdefg"
  -
    :email: "user3@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: logger
    :delivery_options:
      :log_path: "/var/log/user3-email.log"
  -
    :email: "user4@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: letter_opener
    :delete_after_delivery: true
    :expunge_deleted: true
    :delivery_options:
      :location: "/tmp/user4-email"
  -
    :email: "user5@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: sidekiq
    :delivery_options:
      :redis_url: redis://localhost:6379
      :worker: EmailReceiverWorker
  -
    :email: "user6@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: sidekiq
    :delivery_options:
      # When pointing to sentinel, follow this sintax for redis URLs:
      # redis://:<password>@<master-name>/
      :redis_url: redis://:password@my-redis-sentinel/
      :sentinels:
        -
          :host: 127.0.0.1
          :port: 26379
      :worker: EmailReceiverWorker
  -
    :email: "user7@outlook365.com"
    :password: "password"
    :name: "inbox"
    :inbox_method: microsoft_graph
    :inbox_options:
      :tenant_id: 12345
      :client_id: ABCDE
      :client_secret: YOUR-SECRET-HERE
    :delivery_method: sidekiq
    :delivery_options:
      :redis_url: redis://localhost:6379
      :worker: EmailReceiverWorker
```

**Note:** If using `delete_after_delivery`, you also probably want to use
`expunge_deleted` unless you really know what you're doing.

## inbox_method

By default, IMAP mode is assumed for reading a mailbox.

### IMAP Server Configuration ##

You can set per-mailbox configuration for the IMAP server's `host` (default: 'imap.gmail.com'), `port` (default: 993), `ssl` (default: true), and `start_tls` (default: false).

If you want to set additional options for IMAP SSL you can pass a YAML hash to match [SSLContext#set_params](http://docs.ruby-lang.org/en/2.2.0/OpenSSL/SSL/SSLContext.html#method-i-set_params). If you set `verify_mode` to `:none` it'll replace with the appropriate constant.

If you're seeing the error `Please log in via your web browser: https://support.google.com/mail/accounts/answer/78754 (Failure)`, you need to configure your Gmail account to allow less secure apps to access it: https://support.google.com/accounts/answer/6010255.

### Microsoft Graph configuration

To use the Microsoft Graph API instead of IMA to read e-mail, you will
need to create an application in the Azure Active Directory. Follow the
[Microsoft instructions](https://docs.microsoft.com/en-us/azure/active-directory/develop/quickstart-configure-app-expose-web-apis).

1. For MailRoom to work as a service account, this application add the
application permission `Mail.ReadWrite` to read/write mail in *all*
mailboxes. Delegated permissions for a specific user will NOT work.

1. Be sure to grant admin consent for this application.

1. [Create a client secret](https://docs.microsoft.com/en-us/azure/storage/common/storage-auth-aad-app?tabs=dotnet#create-a-client-secret).

1. To ensure this application can only read specific mailboxes, [follow these instructions](https://docs.microsoft.com/en-us/graph/auth-limit-mailbox-access).

1. Obtain the client ID, client secret, and tenant ID for this application.

In the MailRoom, configuration, set `inbox_method` to `microsoft_graph`,
and fill in `inbox_options` with the values obtained above:

```yaml
    :inbox_method: microsoft_graph
    :inbox_options:
      :tenant_id: 12345
      :client_id: ABCDE
      :client_secret: YOUR-SECRET-HERE
```

## delivery_method ##

### postback ###

Requires `faraday` gem be installed.

*NOTE:* If you're using Ruby `>= 2.0`, you'll need to use Faraday from `>= 0.8.9`. Versions before this seem to have some weird behavior with `mail_room`.

The default delivery method, requires `delivery_url` and `delivery_token` in
configuration.

You can pass `content_type:` option to overwrite `faraday's` default content-type(`application/x-www-form-urlencoded`) for post requests, we recommend passing `text/plain` as content-type.

As the postback is essentially using your app as if it were an API endpoint,
you may need to disable forgery protection as you would with a JSON API.

### sidekiq ###

Deliver the message by pushing it onto the configured Sidekiq queue to be handled by a custom worker.

Requires `redis` gem to be installed.

Configured with `:delivery_method: sidekiq`.

Delivery options:
- **redis_url**: The Redis server to connect with. Use the same Redis URL that's used to configure Sidekiq.
  Required, defaults to `redis://localhost:6379`.
- **sentinels**: A list of sentinels servers used to provide HA to Redis. (see [Sentinel Support](#sentinel-support))
  Optional.
- **namespace**: The Redis namespace Sidekiq works under. Use the same Redis namespace that's used to configure Sidekiq.
  Optional.
- **queue**: The Sidekiq queue the job is pushed onto. Make sure Sidekiq actually reads off this queue.
  Required, defaults to `default`.
- **worker**: The worker class that will handle the message.
  Required.

An example worker implementation looks like this:


```ruby
class EmailReceiverWorker
  include Sidekiq::Worker

  def perform(message)
    mail = Mail::Message.new(message)

    puts "New mail from #{mail.from.first}: #{mail.subject}"
  end
end
```

### que ###

Deliver the message by pushing it onto the configured Que queue to be handled by a custom worker.

Requires `pg` gem to be installed.

Configured with `:delivery_method: que`.

Delivery options:
- **host**: The postgresql server host to connect with. Use the database you use with Que.
  Required, defaults to `localhost`.
- **port**: The postgresql server port to connect with. Use the database you use with Que.
  Required, defaults to `5432`.
- **database**: The postgresql database to use. Use the database you use with Que.
  Required.
- **queue**: The Que queue the job is pushed onto. Make sure Que actually reads off this queue.
  Required, defaults to `default`.
- **job_class**: The worker class that will handle the message.
  Required.
- **priority**: The priority you want this job to run at.
  Required, defaults to `100`, lowest Que default priority.

An example worker implementation looks like this:

```ruby
class EmailReceiverJob < Que::Job
  def run(message)
    mail = Mail::Message.new(message)

    puts "New mail from #{mail.from.first}: #{mail.subject}"
  end
end
```

### logger ###

Configured with `:delivery_method: logger`.

If the `:log_path:` delivery option is not provided, defaults to `STDOUT`

### noop ###

Configured with `:delivery_method: noop`.

Does nothing, like it says.

### letter_opener ###

Requires `letter_opener` gem be installed.

Configured with `:delivery_method: letter_opener`.

Uses Ryan Bates' excellent [letter_opener](https://github.com/ryanb/letter_opener) gem.

## ActionMailbox in Rails ##

MailRoom can deliver mail to Rails using the ActionMailbox [configuration options for an SMTP relay](https://edgeguides.rubyonrails.org/action_mailbox_basics.html#configuration).

In summary (from the ActionMailbox docs)

1. Configure Rails to use the `:relay` ingress option:
```rb
# config/environments/production.rb
config.action_mailbox.ingress = :relay
```

2. Generate a strong password (e.g., using SecureRandom or something) and add it to Rails config:
using `rails credentials:edit` under `action_mailbox.ingress_password`.

And finally, configure MailRoom to use the postback configuration with the options:

```yaml
:delivery_method: postback
:delivery_options:
  :delivery_url: https://example.com/rails/action_mailbox/relay/inbound_emails
  :delivery_username: actionmailbox
  :delivery_password: <INGRESS_PASSWORD>
```

## Receiving `postback` in Rails ##

If you have a controller that you're sending to, with forgery protection
disabled, you can get the raw string of the email using `request.body.read`.

I would recommend having the `mail` gem bundled and parse the email using
`Mail.read_from_string(request.body.read)`.

*Note:* If you get the exception (`Rack::QueryParser::InvalidParameterError (invalid %-encoding...`)
it's probably because the content-type is set to Faraday's default, which is  `HEADERS['content-type'] = 'application/x-www-form-urlencoded'`. It can cause `Rack` to crash due to `InvalidParameterError` exception. When you send a post with `application/x-www-form-urlencoded`, `Rack` will attempt to parse the input and can end up raising an exception, for example if the email that you are forwarding contain `%%` in its content or headers it will cause Rack to crash with the message above.

## idle_timeout ##

By default, the IDLE command will wait for 29 minutes (in order to keep the server connection happy).
If you'd prefer not to wait that long, you can pass `idle_timeout` in seconds for your mailbox configuration.

## Search Command ##

This setting allows configuration of the IMAP search command sent to the server. This still defaults 'UNSEEN'. You may find that 'NEW' works better for you.

## Running in Production ##

I suggest running with either upstart or init.d. Check out this wiki page for some example scripts for both: https://github.com/tpitale/mail_room/wiki/Init-Scripts-for-Running-mail_room

## Arbitration ##

When running multiple instances of MailRoom against a single mailbox, to try to prevent delivery of the same message multiple times, we can configure Arbitration using Redis.

```yaml
:mailboxes:
  -
    :email: "user1@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: postback
    :delivery_options:
      :delivery_url: "http://localhost:3000/inbox"
      :delivery_token: "abcdefg"

    :arbitration_method: redis
    :arbitration_options:
      # The Redis server to connect with. Defaults to redis://localhost:6379.
      :redis_url: redis://redis.example.com:6379
      # The Redis namespace to house the Redis keys under. Optional.
      :namespace: mail_room
  -
    :email: "user2@gmail.com"
    :password: "password"
    :name: "inbox"
    :delivery_method: postback
    :delivery_options:
      :delivery_url: "http://localhost:3000/inbox"
      :delivery_token: "abcdefg"

    :arbitration_method: redis
    :arbitration_options:
      # When pointing to sentinel, follow this sintax for redis URLs:
      # redis://:<password>@<master-name>/
      :redis_url: redis://:password@my-redis-sentinel/
      :sentinels:
        -
          :host: 127.0.0.1
          :port: 26379
      # The Redis namespace to house the Redis keys under. Optional.
      :namespace: mail_room
```

**Note:** This will likely never be a _perfect_ system for preventing multiple deliveries of the same message, so I would advise checking the unique `message_id` if you are running in this situation.

**Note:** There are other scenarios for preventing duplication of messages at scale that _may_ be more appropriate in your particular setup. One such example is using multiple inboxes in reply-by-email situations. Another is to use labels and configure a different `SEARCH` command for each instance of MailRoom.

## Sentinel Support

Redis Sentinel provides high availability for Redis. Please read their [documentation](http://redis.io/topics/sentinel)
first, before enabling it with mail_room.

To connect to a Sentinel, you need to setup authentication to both sentinels and redis daemons first, and make sure
both are binding to a reachable IP address.

In mail_room, when you are connecting to a Sentinel, you have to inform the `master-name` and the `password` through
`redis_url` param, following this syntax:

```
redis://:<password>@<master-name>/
```

You also have to inform at least one pair of `host` and `port` for a sentinel in your cluster.
To have a minimum reliable setup, you need at least `3` sentinel nodes and `3` redis servers (1 master, 2 slaves).

## Logging ##

MailRoom will output JSON-formatted logs to give some observability into its operations.

Simply configure a `log_path` for the `logger` on any of your mailboxes. By default, nothing will be logged.

If you wish to log to `STDOUT` or `STDERR` instead of a file, you can pass `:stdout` or `:stderr`,
respectively and MailRoom will log there.

## Contributing ##

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. If accepted, ask for commit rights

## TODO ##

1. specs, this is just a (working) proof of concept √
2. finish code for POSTing to callback with auth √
3. accept mailbox configuration for one account directly on the commandline; or ask for it
4. add example rails endpoint, with auth examples
5. add example configs for upstart/init.d √
6. log to stdout √
7. add a development mode that opens in letter_opener by ryanb √
