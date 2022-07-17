# frozen_string_literal: true

class GeoZone < ActiveRecord::Base
  has_many :users, foreign_key: 'zone_id', inverse_of: :zone
  has_many :subzones, class_name: 'GeoZone', foreign_key: 'parent_zone_id', dependent: :destroy
  belongs_to :parent_zone, class_name: 'GeoZone'
end
