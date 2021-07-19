class Endpoint < ApplicationRecord
  include Blockable
  include Notifiable

  has_secure_token :authentication_token
  # attribute :locale, :string, default: "en"
  attribute :token

  belongs_to :user, optional: true
  has_many :settings, dependent: :destroy
  has_many :packages, through: :settings

  validates :name,
            length: { maximum: MAX_NAME_LENGTH }
  validates :locale,
            length: { maximum: 10 }
  validates :authentication_token,
            allow_nil: true,
            length: { is: 24 }

  def installed?(package)
    settings.exists?(package: package)
  end

  def install(package)
    settings.create(package: package)
    Rails.cache.delete_matched("SettingsIndex_#{id}")
  end

  def actualized_settings
    Rails.cache.fetch(
      "SettingsIndex_#{id}",
      expires_in: MODEL_CACHE_TIMEOUT,
    ) do
      ActualizedSettingsService.call(settings)
    end
  end

  def reset_token
    regenerate_authentication_token
    self.token = Api::Token.encode(self)
  end

  def can_view?(object)
    object.published? || user&.can_view?(object)
  end
end
