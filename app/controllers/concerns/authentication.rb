module Authentication
  def cache_fetch(model, id, token)
    cached_instance = model.fetch(id)
    if ActiveSupport::SecurityUtils.secure_compare(cached_instance&.authentication_token, token) &&
       !cached_instance&.blocked?
       cached_instance
    else
      raise Pundit::NotAuthorizedError
    end
  end

  def current_user
    current_endpoint&.user || devise_current_user
  end

  def current_resource
    current_endpoint || devise_current_user
  end

  def current_endpoint
    @sign_in_endpoint
  end

  def sign_in_endpoint(endpoint)
    @sign_in_endpoint ||= endpoint
  end

  def endpoint_signed_in?
    current_endpoint.present?
  end

  def reset_token!
    response.set_header('Access-Token', current_resource.reset_token!)
  end

  def authenticate_endpoint!
    @endpoint =
      current_endpoint ||
      Endpoint.find_by(id: params[:endpoint_id] || params[:id], user: current_user)
    raise Pundit::NotAuthorizedError unless endpoint_signed_in?

    authorize @endpoint, :show?, policy_class: EndpointPolicy
  end

  def forbid_for_endpoint!
    raise Pundit::NotAuthorizedError if endpoint_signed_in?
  end

  def decode_token(token)
    payload =
      JWT.decode(
        token,
        Rails.application.credentials.jwt_secret,
        true,
        { algorithm: "HS256" },
      ).first.with_indifferent_access
    return payload[:scope], payload[:uuid], payload[:token]
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  private

  def devise_current_user
    @devise_current_user ||= warden.authenticate(scope: :user)
  end
end
