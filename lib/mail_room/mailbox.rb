module MailRoom
  Mailbox = Struct.new(*[
    :email,
    :password,
    :name,
    :delivery_method, # :noop, :logger, :postback, :letter_opener
    :log_path, # for logger
    :delivery_url, # for postback
    :delivery_token, # for postback
    :location # for letter_opener
  ])

  class Mailbox
    def initialize(attributes={})
      super(*attributes.values_at(*members))
    end
  end
end
