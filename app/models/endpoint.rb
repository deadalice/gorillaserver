class Endpoint < ApplicationRecord
  include IdentityCache
  include Blockable
  include Notifiable
  include TokenResetable

  # attribute :locale, :string, default: "en"

  belongs_to :user, optional: true
  has_many :settings, dependent: :destroy
  has_many :packages, through: :settings
  # TODO: Noticed has_many :notifications, as: :recipient, dependent: :destroy

  validates :name, length: { maximum: MAX_NAME_LENGTH }
  validates :locale, length: { maximum: 10 }

  def installed?(package)
    settings.exists?(package: package)
  end
end
