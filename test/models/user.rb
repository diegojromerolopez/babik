
class User < ActiveRecord::Base
  belongs_to :zone, foreign_key: 'zone_id', class_name: 'GeoZone', optional: true, inverse_of: :users
  has_many :posts, foreign_key: 'author_id', class_name: 'Post'
end
