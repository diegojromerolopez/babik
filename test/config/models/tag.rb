# frozen_string_literal: true

class Tag < ActiveRecord::Base
  has_many :post_tags
  has_many :posts, through: :post_tags, inverse_of: :tags
end
