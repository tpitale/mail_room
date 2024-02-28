## mail_room 0.11.1 ##

https://github.com/tpitale/mail_room/compare/v0.11.0...v0.11.1

## mail_room 0.11.0 ##

https://github.com/tpitale/mail_room/compare/v0.10.1...v0.11.0

## mail_room 0.10.1 ##

* Fix db attribute on redis URL PR#130 - @jarkaK

## mail_room 0.10.0 ##

* Remove imap backports
* Increase minimum ruby version to 2.3
* Postback basic_auth support - PR#92
* Docs for ActionMailbox - PR#92
* Configuration option for delivery_klass - PR#93
* Expunge deleted - PR#90
* Raise error on a few fields of missing configuration - PR#89
* Remove fakeredis gem - PR#87

    *Tony Pitale <@tpitale>*

* Fix redis arbitration to use NX+EX - PR#86

    *Craig Miskell <@craigmiskell-gitlab>*

* Structured (JSON) logger - PR#88

    *charlie <@cablett>*

## mail_room 0.9.1 ##

* __FILE__ support in yml ERb config - PR#80

    *Gabriel Mazetto <@brodock>*

## mail_room 0.9.0 ##

* Redis Sentinel configuration support - PR#79

    *Gabriel Mazetto <@brodock>*

## mail_room 0.8.1 ##

* Check watching thread exists before joining - PR#78

    *Michal Galet <@galet>*

## mail_room 0.8.0 ##

* Rework the mailbox watcher and handler into a new Connection class to abstract away IMAP handling details

    *Tony Pitale <@tpitale>*

## mail_room 0.7.0 ##

* Backports idle timeout from ruby 2.3.0
* Sets default to 29 minutes to prevent IMAP disconnects
* Validates that the timeout does not exceed 29 minutes

    *Tony Pitale <@tpitale>*

## mail_room 0.6.1 ##

* ERB parsing of configuration yml file to enable using ENV variables

    *Douwe Maan <@DouweM>*

## mail_room 0.6.0 ##

* Add redis Arbitration to reduce multiple deliveries of the same message when running multiple MailRoom instances on the same inbox

    *Douwe Maan <@DouweM>*

## mail_room 0.5.2 ##

* Fix Sidekiq delivery method for non-UTF8 email

    *Douwe Maan <@DouweM>*

* Add StartTLS session support

    *Tony Pitale <@tpitale>*

## mail_room 0.5.1 ##

* Re-idle after 29 minutes to maintain IDLE connection

    *Douwe Maan <@DouweM>*

## mail_room 0.5.0 ##

* Que delivery method

    *Tony Pitale <@tpitale>*

## mail_room 0.4.2 ##

* rescue from all IOErrors, not just EOFError

    *Douwe Maan <@DouweM>*

## mail_room 0.4.1 ##

* Fix redis default host/port configuration
* Mailbox does not attempt delivery without a message

    *Douwe Maan <@DouweM>*

## mail_room 0.4.0 ##

* Sidekiq delivery method
* Option to delete messages after delivered

    *Douwe Maan <@DouweM>*

* -q/--quiet do not raise errors on missing configuration
* prefetch mail messages before idling
* delivery-method-specific delivery options configuration

    *Tony Pitale <@tpitale>*

## mail_room 0.3.1 ##

* Rescue from EOFError and re-setup mailroom

    *Tony Pitale <@tpitale>*

## mail_room 0.3.0 ##

*   Reconnect and idle if disconnected during an existing idle.
*   Set idling thread to abort on exception so any unhandled exceptions will stop mail_room running.

    *Tony Pitale <@tpitale>*
