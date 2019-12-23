class Package < ApplicationRecord
  include Discard::Model

  has_many :parts, dependent: :destroy
  has_many :settings
  has_many :endpoints, through: :settings
  has_and_belongs_to_many :dependencies,
    class_name: "Package",
    join_table: :dependencies,
    foreign_key: :package_id,
    association_foreign_key: :dependent_package_id
  belongs_to :user, optional: true
  has_one_attached :icon

  after_create :create_main_part

  validates :alias, format: { with: /\A[A-Za-z\d\-_ ]*\z/ }

  default_scope -> {
    with_attached_icon
  }

  def all_dependencies(packages = [])
    dependencies.map do |p|
      if !packages.include?(p)
        if p.dependencies.size > 0
          packages << p
        else
          packages.unshift(p)
        end
        # TODO: May be, counter?
        all_dependencies(packages)
      end
    end
    packages
  end

  def to_yaml
    #
  end

  def to_param
    key
  end

  private

  def create_main_part
    parts.create(
      name: 'main'
    )
  end

end
