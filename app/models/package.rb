class Package < ApplicationRecord
  include Blockable
  include Publishable
  extend Enumerize

  # TODO: Messages for feed/forum - like update news etc.

  # TODO: Markers to detect package is already installed:
  # - registry key
  # - file exists

  translates :caption, :description
  enumerize :package_type,
            in: %i[bundle external component],
            scope: true
  jsonb_accessor :data,
                 path: [:string, default: ""],
                 path_persistent: [:boolean, default: false],
                 allow_api_access: [:string, array: true, default: []],
                 require_administrator: [:boolean, default: false]

  belongs_to :user
  has_one :product
  has_many :settings, dependent: :nullify
  has_many :endpoints, through: :settings
  has_many :sources, dependent: :destroy
  has_many :dependencies
  has_many :dependent_packages, through: :dependencies
  has_many :maintains
  has_many :maintainers, through: :maintains,
                         source: :user
  belongs_to :replacement,
             class_name: "Package",
             optional: true
  has_one_attached :icon,
                   service: :internal,
                   dependent: :purge_later

  # before_create :init_data

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
  validates :package_type,
            presence: true
  validates :icon,
            size: { less_than: MAX_ICON_SIZE }
  validates :replacement,
            package_replacement: true
  validates :caption,
            presence: true,
            length: {
              minimum: MIN_NAME_LENGTH,
              maximum: MAX_NAME_LENGTH,
            }
  validates_with PackageSubscriptionValidator

  scope :with_includes, -> { joins(:user) }

  def get_components
    Package::Component.extract(self)
  end

  def replaced_by
    _replaced_by unless replacement_id.nil?
  end

  def external?
    !external_url.to_s.strip.empty?
  end

  def generate_filelist!
    available_files = Set[]
    sources.map do |s|
      available_files += s.files.keys
      available_files -= s.delete_files.keys
    end
    # It would be strange if we allow to delete files added by the same source
    available_files -= sources.last.files.keys if sources.size > 0
    update(files: available_files)
  end

  private

  def _replaced_by
    # TODO: Check payment i.e.
    replacement_id.nil? ? self : replacement.replaced_by
  end
end
