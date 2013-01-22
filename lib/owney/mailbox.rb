module Owney
  Mailbox = Struct.new(:email, :password, :name, :delivery_url, :delivery_token)

  class Mailbox
    def initialize(attributes={})
      super(*attributes.values_at(*members))
    end
  end
end
