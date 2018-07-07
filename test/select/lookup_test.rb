# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of different lookups available in both methods filter and exclude
class LookupTest < Minitest::Test

  def setup
    Post.create!(title: 'This other post of 5 stars', stars: 5)
    Post.create!(title: 'This a post of 5 stars', stars: 5)
    Post.create!(title: 'This a post of 4 stars', stars: 4)
    Post.create!(title: 'This a post of 3 stars', stars: 3)
    Post.create!(title: 'This other post with 3 stars', stars: 3)

    Post.create!(title: 'Old post 1', stars: 0, created_at: Time.now - 1.month)
    Post.create!(title: 'Old post 2', stars: 0, created_at: Time.now - 10.months)
  end

  def teardown
    Post.destroy_all
  end

  def test_gt
    posts_with_more_than_4_starts = Post.objects.filter(stars__gt: 4).order_by(created_at: :ASC)
    assert_equal 2, posts_with_more_than_4_starts.count
    assert_equal 'This other post of 5 stars', posts_with_more_than_4_starts[0].title
    assert_equal 'This a post of 5 stars', posts_with_more_than_4_starts[1].title
  end

  def test_gte
    posts_with_more_or_equal_than_4_starts = Post.objects.filter(stars__gte: 4).order_by(created_at: :ASC)
    assert_equal 3, posts_with_more_or_equal_than_4_starts.count
    assert_equal 'This other post of 5 stars', posts_with_more_or_equal_than_4_starts[0].title

    assert_nil posts_with_more_or_equal_than_4_starts[100]
  end

  def test_lt
    posts_with_less_than_4_starts = Post.objects.filter(stars__lt: 4).order_by(created_at: :ASC)
    assert_equal 4, posts_with_less_than_4_starts.count
    assert_equal 'Old post 2', posts_with_less_than_4_starts[0].title
    assert_equal 'Old post 1', posts_with_less_than_4_starts[1].title
  end

  def test_lte
    posts_with_less_or_equal_than_4_starts = Post.objects.filter(stars__lte: 4).order_by(created_at: :ASC)
    assert_equal 5, posts_with_less_or_equal_than_4_starts.count
    assert_equal 'Old post 2', posts_with_less_or_equal_than_4_starts[0].title
    assert_equal 'Old post 1', posts_with_less_or_equal_than_4_starts[1].title
    assert_equal 'This a post of 4 stars', posts_with_less_or_equal_than_4_starts[2].title
    assert_equal 'This a post of 3 stars', posts_with_less_or_equal_than_4_starts[3].title
    assert_equal 'This a post of 3 stars', posts_with_less_or_equal_than_4_starts[3].title
  end

  def test_between
    posts_3_4_stars = Post.objects.filter(stars__between: [3, 4]).order_by(created_at: :ASC)
    posts_3_4_stars_range = Post.objects.filter(stars__range: [3, 4]).order_by(created_at: :ASC)
    assert_equal 3, posts_3_4_stars.count
    assert_equal 3, posts_3_4_stars_range.count
    assert_equal 'This a post of 4 stars', posts_3_4_stars[0].title
    assert_equal 'This a post of 3 stars', posts_3_4_stars[1].title
    assert_equal 'This other post with 3 stars', posts_3_4_stars[2].title
  end

  def test_between_dates
    old_posts = Post.objects.filter(created_at__between: [Time.now - 2.months, Time.now]).order_by(created_at: :ASC)
    old_posts_range = Post.objects.filter(created_at__range: [Time.now - 2.months, Time.now]).order_by(created_at: :ASC)
    assert_equal 1, old_posts.count
    assert_equal 1, old_posts_range.count
    assert_equal 'Old post 1', old_posts[0].title
    assert_equal 'Old post 1', old_posts_range[0].title
  end

  def test_date
    today_posts = Post.objects.filter(created_at__date: Date.today).order_by(created_at: :ASC)
    assert_equal 5, today_posts.count
  end

  def test_year
    today_posts = Post.objects.filter(created_at__year: Date.today.year).order_by(created_at: :ASC)
    #puts today_posts.select_sql
   # assert_equal 7, today_posts.count
  end

  def test_regex
    other_posts = Post.objects.filter(title__regex: /^This other[\w\d\s]+$/).order_by(created_at: :ASC)
    assert other_posts.select_sql.include?("(posts.title REGEXP '^This other[\\w\\d\\s]+$/')")
  end

  def test_iregex
    other_posts = Post.objects.filter(title__iregex: /^This other[\w\d\s]+$/).order_by(created_at: :ASC)
    assert other_posts.select_sql.include?("(posts.title REGEXP '(?i)^This other[\\w\\d\\s]+$/')")
  end
end