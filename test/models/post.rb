
class Post < ActiveRecord::Base
  belongs_to :author, foreign_key: 'author_id', class_name: 'User', inverse_of: :posts
  belongs_to :category, inverse_of: :posts
  has_many :post_tags
  has_many :tags, through: :post_tags, inverse_of: :posts

  def add_tag(tag)
    PostTag.create!(post: self, tag: tag)
  end

end