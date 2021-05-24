class Package < ApplicationRecord
  include Blockable
  include Publishable

  # TODO: MUST!!! Sign packages with endpoint certificate before send and check sign on client-side.

  # TODO: Messages for feed/forum

  # TODO: Markers to detect package is already installed:
  # - registry key
  # - file exists

  belongs_to :user
  has_one :product
  has_many :settings, dependent: :nullify
  has_many :endpoints, through: :settings
  has_many :sources, dependent: :destroy
  has_many :dependencies
  has_many :components, through: :dependencies
  has_many :maintains
  has_many :maintainers, through: :maintains,
                         source: :user

  belongs_to :replacement,
             class_name: "Package",
             optional: true
  has_one_attached :icon,
                   service: :internal,
                   dependent: :purge_later

  validates :name,
            name_restrict: true,
            presence: true,
            length: {
              minimum: MIN_NAME_LENGTH,
              maximum: MAX_NAME_LENGTH,
            },
            uniqueness: {
              scope: :user_id,
              case_sensitive: false,
            },
            format: { with: NAME_FORMAT }
  validates :icon, size: { less_than: MAX_ICON_SIZE }
  validates :external_url,
            format: URI.regexp(%w[https]),
            length: { maximum: 2048 },
            allow_nil: true
  validates :replacement,
            package_replacement: true

  after_save :check_external_url

  scope :with_includes, -> { joins(:user) }

  scope :apps, -> {
      includes(:icon_attachment)
        .where(is_component: false)
    }

  def all_components
    Component.extract(self)
  end

  def replaced_by
    _replaced_by unless replacement_id.nil?
  end

  def external?
    !external_url.to_s.strip.empty?
  end

  def validated?
    external? ? validated_at.present? : sources.where.not(validated_at: nil).any?
  end

  def published?
    external? ? published_at.present? : sources.where.not(published_at: nil).any?
  end

  private

  def check_external_url
    if saved_change_to_external_url?
      invalidate!
      CheckExternalUrlJob.perform_later self
    end
  end

  def _replaced_by
    # TODO: Check payment i.e.
    replacement_id.nil? ? self : replacement.replaced_by
  end
end
