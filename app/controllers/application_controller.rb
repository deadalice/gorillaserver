class ApplicationController < ActionController::Base
  include ApplicationHelper
  include Pagy::Backend
  include Pundit
  include Api::Cache

  protect_from_forgery with: :exception, unless: -> { request.format.json? }
  before_action :configure_permitted_parameters, if: :devise_controller?
  before_action :api_check_headers, if: -> { request.format.json? }
  before_action :set_locale

  rescue_from ActiveRecord::RecordNotFound, with: :render_404
  rescue_from Pundit::NotAuthorizedError, with: :render_403

  protected

  # TODO: Layout
  def render_403
    respond_to do |format|
      format.html { render "errors/403", layout: "errors", status: :forbidden }
      format.any { head :forbidden }
    end
  end

  def render_404
    respond_to do |format|
      format.html { render "errors/404", layout: "errors", status: :not_found }
      format.any { head :not_found }
    end
  end

  def render_json_error(messages, status:)
    if messages.is_a? Array
      render json: { errors: messages }, status: status
    else
      render json: { error: messages }, status: status
    end
  end

  private

  def api_check_headers
    return true if Rails.env.test?

    service = request.headers["X-API-Service"]
    if request.headers["Authorization"].present?
      scope, uuid, token = decode_token(request.headers["Authorization"])
      unless uuid
        render_json_error I18n.t("devise.failure.timeout"),
                          status: :unauthorized
      end
    end

    if Api::Keys.new.find(service)
      if scope == "Endpoint"
        unless sign_in_endpoint cached_endpoint(uuid, token)
          render_json_error I18n.t("devise.failure.unauthenticated"),
                            status: :unauthorized
        end
        if current_endpoint.remote_ip != request.remote_ip
          Rails.logger.warn "Endpoint #{current_endpoint.id} IP changed from #{current_endpoint.remote_ip} to #{request.remote_ip}"
          current_endpoint.update(remote_ip: request.remote_ip,
                                  reseted_at: nil)
        end
      elsif scope == "User"
        unless sign_in cached_user(uuid, token)
          render_json_error I18n.t("devise.failure.unauthenticated"),
                            status: :unauthorized
        end
      end
    elsif service.present?
      head :upgrade_required
    else
      Rails.logger.warn "Forbidden request from #{request.remote_ip}"
      head :forbidden
    end
  end

  def decode_token(token)
    payload =
      JWT
        .decode(
          token,
          Rails.application.credentials.jwt_secret,
          true,
          { algorithm: "HS256" },
        )
        .first
        .with_indifferent_access
    return payload[:scope], payload[:uuid], payload[:token]
  rescue JWT::ExpiredSignature, JWT::DecodeError
    nil
  end

  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[fullname name locale])
    devise_parameter_sanitizer.permit(
      :account_update,
      keys: %i[fullname name locale],
    )
  end

  def set_locale
    session[:locale] ||=
      current_endpoint&.locale || current_user&.locale ||
        http_accept_language.compatible_language_from(I18n.available_locales) ||
        I18n.default_locale.to_s
    I18n.locale = session[:locale]
  end

  def pundit_user
    current_anyone
  end
end
