
class Post < ActiveRecord::Base
  belongs_to :author, foreign_key: 'author_id', class_name: 'User', inverse_of: :posts
  belongs_to :category, inverse_of: :posts
  has_many :post_tags
  has_many :tags, through: :post_tags, inverse_of: :posts

  def add_tag(tag)
    begin
      PostTag.create!(post: self, tag: tag)
    rescue ActiveRecord::RecordNotUnique
    end
  end

  def add_tag_by_name(tag_name)
    begin
      new_tag = Tag.create!(name: tag_name)
    rescue ActiveRecord::RecordNotUnique
      new_tag = Tag.find_by(name: tag_name)
    end
    add_tag(new_tag)
  end

end