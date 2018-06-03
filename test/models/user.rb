
class User < ActiveRecord::Base
  has_many :posts
  has_many :tags, through: :posts
end