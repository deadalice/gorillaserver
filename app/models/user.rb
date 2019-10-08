class User < ApplicationRecord
  include Discard::Model
  #acts_as_tagger
  #acts_as_taggable

  has_many :packages, dependent: :destroy
  has_many :endpoints, dependent: :destroy
  belongs_to :user, optional: true
end
