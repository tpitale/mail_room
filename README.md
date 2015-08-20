# mail_room #

mail_room is a configuration based process that will idle on IMAP connections and POST to a delivery URL whenever a new message is received on the configured mailbox and folder.

[![Build Status](https://travis-ci.org/tpitale/mail_room.png?branch=master)](https://travis-ci.org/tpitale/mail_room)
[![Code Climate](https://codeclimate.com/github/tpitale/mail_room.png)](https://codeclimate.com/github/tpitale/mail_room)

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
    :delivery_options:
      :delivery_url: "http://localhost:3000/inbox"
      :delivery_token: "abcdefg"
    
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
```

## delivery_method ##

### postback ###

Requires `faraday` gem be installed.

*NOTE:* If you're using Ruby `>= 2.0`, you'll need to use Faraday from `>= 0.8.9`. Versions before this seem to have some weird behavior with `mail_room`.

The default delivery method, requires `delivery_url` and `delivery_token` in 
configuration.

As the postback is essentially using your app as if it were an API endpoint, 
you may need to disable forgery protection as you would with a JSON API. In 
our case, the postback is plaintext, but the protection will still need to be 
disabled.

### sidekiq ###

Deliver the message by pushing it onto the configured Sidekiq queue to be handled by a custom worker.

Requires `redis` gem to be installed.

Configured with `:delivery_method: sidekiq`.

Delivery options:
- **redis_url**: The Redis server to connect with. Use the same Redis URL that's used to configure Sidekiq.
  Required, defaults to `redis://localhost:6379`.
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

### logger ###

Configured with `:delivery_method: logger`.

If `:log_path:` is not provided, defaults to `STDOUT`

### noop ###

Configured with `:delivery_method: noop`.

Does nothing, like it says.

### letter_opener ###

Requires `letter_opener` gem be installed.

Configured with `:delivery_method: letter_opener`.

Uses Ryan Bates' excellent [letter_opener](https://github.com/ryanb/letter_opener) gem.

## Receiving `postback` in Rails ##

If you have a controller that you're sending to, with forgery protection
disabled, you can get the raw string of the email using `request.body.read`.

I would recommend having the `mail` gem bundled and parse the email using
`Mail.read_from_string(request.body.read)`.

## Search Command ##

This setting allows configuration of the IMAP search command sent to the server. This still defaults 'UNSEEN'. You may find that 'NEW' works better for you.

## IMAP Server Configuration ##

You can set per-mailbox configuration for the IMAP server's `host` (default: 'imap.gmail.com'), `port` (default: 993), and `ssl` (default: true). 

If you're seeing the error `Please log in via your web browser: https://support.google.com/mail/accounts/answer/78754 (Failure)`, you need to configure your Gmail account to allow less secure apps to access it: https://support.google.com/accounts/answer/6010255.

## Running in Production ##

I suggest running with either upstart or init.d. Check out this wiki page for some example scripts for both: https://github.com/tpitale/mail_room/wiki/Init-Scripts-for-Running-mail_room

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
