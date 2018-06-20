
class GeoZone < ActiveRecord::Base
  has_many :users
  has_many :subzones, class_name: 'GeoZone', foreign_key: 'parent_zone_id', dependent: :destroy
  belongs_to :parent_zone, class_name: 'GeoZone'
end
