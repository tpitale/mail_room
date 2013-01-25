# mail_room #

mail_room is a configuration based process that will idle on IMAP connections and POST to a delivery URL whenever a new message is received on the configured mailbox and folder.

## Installation ##

Add this line to your application's Gemfile:

    gem 'mail_room'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mail_room

## Usage ##

    bin/mail_room -f /path/to/config.yml

## Configuration ##

    ---
      :mailboxes:
        -
          :email: "user1@gmail.com"
          :password: "password"
          :name: "inbox"
          :delivery_url: "http://localhost:3000/inbox"
          :delivery_token: "abcdefg"
        -
          :email: "user2@gmail.com"
          :password: "password"
          :name: "inbox"
          :delivery_url: "http://localhost:3000/inbox"
          :delivery_token: "abcdefg"

## Dependencies ##

* celluloid

## Contributing ##

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
6. If accepted, ask for commit rights

## TODO ##

1. specs, this is just a (working) proof of concept
2. finish code for POSTing to callback with auth
3. add example rails endpoint, with auth examples
4. remove backgrounding
5. add example configs for god/upstart
