class Package < ApplicationRecord
  include Blockable

  # TODO: MUST!!! Sign packages with endpoint certificate before send and check sign on client-side.

  belongs_to :user
  has_many :settings, dependent: :destroy
  has_many :endpoints, through: :settings
  has_many :sources, dependent: :destroy
  # TODO: Remove files like GIT after delete by nullifying crc in filelist

  has_and_belongs_to_many :dependencies,
                          class_name: "Package",
                          join_table: :dependencies,
                          foreign_key: :package_id,
                          association_foreign_key: :dependent_package_id
  belongs_to :replacement, class_name: "Package", optional: true

  has_one_attached :icon,
                   service: :remote,
                   dependent: :purge_later

  validates :name,
            name_restrict: true,
            presence: true,
            length: {
              minimum: MIN_NAME_LENGTH,
              maximum: MAX_NAME_LENGTH,
            },
            uniqueness: { scope: :user_id, case_sensitive: false },
            format: { with: NAME_FORMAT }
  # TODO: Move aliases to table
  validates :alias,
            name_restrict: true,
            allow_blank: true,
            length: {
              minimum: MIN_NAME_LENGTH,
              maximum: MAX_NAME_LENGTH,
            },
            uniqueness: { case_sensitive: false },
            format: { with: NAME_FORMAT }
  validates :icon, size: { less_than: MAX_ICON_SIZE }
  # TODO: Check link for content disposition
  validates :external_url,
            format: URI.regexp(%w[http https]),
            allow_nil: true
  validates :replacement,
            package_replacement: true
  # TODO enumerate validates :destination
  validates :group_name,
            length: { maximum: MAX_NAME_LENGTH }
  validates :external_url,
            length: { maximum: 2048 }

  scope :allowed_for,
        ->(user) {
          # TODO Remove nil user, because user can't be blank
          # TODO Group permissions
          where(user: user).or(where(published: true))
        }

  def all_dependencies(packages = Set[])
    Package.all_dependencies(self, packages)
    packages.to_a.reverse
  end

  def self.all_dependencies(package, packages = Set[])
    package.dependencies.map do |p|
      packages << p
      Package.all_dependencies(p, packages)
    end
  end

  def self.find_by_alias(value)
    where(id: value).or(
      where(alias: value).or(
        where(name: value)
      )
    ).first
  end

  def replaced?
    replacement.present?
  end

  def replaced_by
    _replaced_by unless replacement.nil?
  end

  def title
    self.alias.present? ? "#{self.name} [#{self.alias}]" : self.name
  end

  def internal?
    external_url.nil? && sources.any?
  end

  def external?
    external_url.present?
  end

  private

  def _replaced_by
    replacement.nil? ? self : replacement.replaced_by
  end
end
