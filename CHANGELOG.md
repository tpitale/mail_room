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
