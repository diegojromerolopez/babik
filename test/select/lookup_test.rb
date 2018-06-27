# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of count method
class LookupTest < Minitest::Test

  def setup
    Post.create!(title: 'This other post of 5 stars', stars: 5)
    Post.create!(title: 'This a post of 5 stars', stars: 5)
    Post.create!(title: 'This a post of 4 stars', stars: 4)
    Post.create!(title: 'This a post of 3 stars', stars: 3)
    Post.create!(title: 'This other post with 3 stars', stars: 3)
  end

  def teardown
    Post.destroy_all
  end

  def test__gt
    posts_with_more_than_4_starts = Post.objects.filter(stars__gt: 4).order_by(created_at: :ASC)
    assert_equal 2, posts_with_more_than_4_starts.count
    assert_equal 'This other post of 5 stars', posts_with_more_than_4_starts[0].title
    assert_equal 'This a post of 5 stars', posts_with_more_than_4_starts[1].title
  end

  def test__gte
    posts_with_more_or_equal_than_4_starts = Post.objects.filter(stars__gte: 4).order_by(created_at: :ASC)
    assert_equal 3, posts_with_more_or_equal_than_4_starts.count
    assert_equal 'This other post of 5 stars', posts_with_more_or_equal_than_4_starts[0].title

    assert_nil posts_with_more_or_equal_than_4_starts[100]
  end

  def test__lt
    posts_with_less_than_4_starts = Post.objects.filter(stars__lt: 4).order_by(created_at: :ASC)
    assert_equal 2, posts_with_less_than_4_starts.count
    assert_equal 'This a post of 3 stars', posts_with_less_than_4_starts[0].title
    assert_equal 'This other post with 3 stars', posts_with_less_than_4_starts[1].title
  end

  def test__lte
    posts_with_less_or_equal_than_4_starts = Post.objects.filter(stars__lte: 4).order_by(created_at: :ASC)
    assert_equal 3, posts_with_less_or_equal_than_4_starts.count
    assert_equal 'This a post of 4 stars', posts_with_less_or_equal_than_4_starts[0].title
    assert_equal 'This a post of 3 stars', posts_with_less_or_equal_than_4_starts[1].title
    assert_equal 'This other post with 3 stars', posts_with_less_or_equal_than_4_starts[2].title
  end
end