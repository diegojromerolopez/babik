# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Check that inverse_of is required in all associations
class InverseOfRequiredTest < Minitest::Test
  def setup
    main_category = Category.create!(name: 'Category not used')
    bad_post = BadPost.create!(title: 'This is a bad post', category: main_category)
    BadTag.create!(name: 'bad tag 1', bad_post: bad_post)
    BadTag.create!(name: 'bad tag 2', bad_post: bad_post)
  end

  def teardown
    BadTag.delete_all
    BadPost.delete_all
    Category.delete_all
  end

  def test_association_without_inverse
    exception = assert_raises RuntimeError do
      bad_post = BadPost.all.first
      bad_post.objects(:bad_tags)
    end
    assert_equal(
      'Relationship bad_tags of model BadPost has no inverse_of option.',
      exception.message
    )
  end
end
