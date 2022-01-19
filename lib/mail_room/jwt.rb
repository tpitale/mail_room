# frozen_string_literal: true

require 'faraday'
require 'securerandom'
require 'jwt'
require 'base64'

module MailRoom
  # Responsible for validating and generating JWT token
  class JWT
    DEFAULT_ISSUER = 'mailroom'
    DEFAULT_ALGORITHM = 'HS256'

    attr_reader :header, :secret_path, :issuer, :algorithm

    def initialize(header:, secret_path:, issuer:, algorithm:)
      @header = header
      @secret_path = secret_path
      @issuer = issuer || DEFAULT_ISSUER
      @algorithm = algorithm || DEFAULT_ALGORITHM
    end

    def valid?
      [@header, @secret_path, @issuer, @algorithm].none?(&:nil?)
    end

    def token
      return nil unless valid?

      secret = Base64.strict_decode64(File.read(@secret_path).chomp)
      payload = { nonce: SecureRandom.hex(12), iss: @issuer }
      ::JWT.encode payload, secret, @algorithm
    end
  end
end
