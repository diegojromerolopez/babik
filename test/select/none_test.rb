# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of none method
class NoneTest < Minitest::Test
  def setup
    [1..100].each do |i|
      Post.create!(title: "Post #{i}", stars: 5)
    end
  end

  def teardown
    Post.destroy_all
  end

  def test_none
    no_posts = Post.objects.none
    assert_equal 0, no_posts.count
    i = 100
    no_posts.each do |_post|
      i -= 1
    end
    assert_equal 100, i
  end

  def test_deep_none_call
    no_posts = Post.objects.filter(stars: 5).none
    assert_equal 0, no_posts.count
    i = 100
    no_posts.each do |_post|
      i -= 1
    end
    assert_equal 100, i
  end
end
