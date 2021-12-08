require 'spec_helper'

require 'mail_room/jwt'

describe MailRoom::JWT do
  let(:secret_path) { File.expand_path('../fixtures/jwt_secret', File.dirname(__FILE__)) }
  let(:secret) { Base64.strict_decode64(File.read(secret_path).chomp) }

  let(:standard_config) do
    {
      secret_path: secret_path,
      issuer: 'mailroom',
      header: 'Mailroom-Api-Request',
      algorithm: 'HS256'
    }
  end

  describe '#token' do
    let(:jwt) { described_class.new(**standard_config) }

    it 'generates a valid jwt token' do
      token = jwt.token
      expect(token).not_to be_empty

      payload = nil
      expect do
        payload = JWT.decode(token, secret, true, iss: 'mailroom', verify_iss: true, algorithm: 'HS256')
      end.not_to raise_error
      expect(payload).to be_an(Array)
      expect(payload).to match(
        [
          a_hash_including(
            'iss' => 'mailroom',
            'nonce' => be_a(String)
          ),
          { 'alg' => 'HS256' }
        ]
      )
    end

    it 'generates a different token for each invocation' do
      expect(jwt.token).not_to eql(jwt.token)
    end
  end

  describe '#valid?' do
    it 'returns true if all essential components are present' do
      jwt = described_class.new(**standard_config)
      expect(jwt.valid?).to eql(true)
    end

    it 'returns true if header and secret path are present' do
      jwt = described_class.new(
        secret_path: secret_path,
        header: 'Mailroom-Api-Request',
        issuer: nil,
        algorithm: nil
      )
      expect(jwt.valid?).to eql(true)
      expect(jwt.issuer).to eql(described_class::DEFAULT_ISSUER)
      expect(jwt.algorithm).to eql(described_class::DEFAULT_ALGORITHM)
    end

    it 'returns false if either header or secret_path are missing' do
      expect(described_class.new(
        secret_path: nil,
        header: 'Mailroom-Api-Request',
        issuer: nil,
        algorithm: nil
      ).valid?).to eql(false)
      expect(described_class.new(
        secret_path: secret_path,
        header: nil,
        issuer: nil,
        algorithm: nil
      ).valid?).to eql(false)
    end
  end
end
