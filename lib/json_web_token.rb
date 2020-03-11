class JsonWebToken
  require 'jwt'

  def self.encode(resource)
    payload = {
      key: resource.key,
      token: resource.authentication_token,
      exp: Time.current.to_i - Rails.application.config.token_expiration_time.to_i
    }
    JWT.encode(payload.to_a.shuffle.to_h, Rails.application.credentials.hmac_secret_key, 'HS256')
  end

  def self.decode(token)
    payload = JWT.decode(token, Rails.application.credentials.hmac_secret_key, true, { algorithm: 'HS256' })&.
      first&.with_indifferent_access
  rescue JWT::ExpiredSignature, JWT::DecodeError
    false
  end

end