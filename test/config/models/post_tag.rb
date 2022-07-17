# frozen_string_literal: true

class PostTag < ActiveRecord::Base
  belongs_to :post, inverse_of: :post_tags
  belongs_to :tag, inverse_of: :post_tags
end
