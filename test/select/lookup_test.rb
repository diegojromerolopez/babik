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

    Post.create!(title: 'Yesteryear post 1', created_at: Time.now - 1.year)
    Post.create!(title: 'Yesteryear post 2', created_at: Time.now - 10.year)
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

  def test_in
    posts_with_odd_stars = Post.objects.filter(stars__in: [5, 3, 1])
    posts_with_5_stars = Post.objects.filter(stars: 5)
    posts_with_3_stars = Post.objects.filter(stars: 3)
    posts_with_1_star = Post.objects.filter(stars: 1)

    assert_equal 2, posts_with_5_stars.count
    assert_equal 2, posts_with_3_stars.count
    assert_equal 0, posts_with_1_star.count
    assert_equal 4, posts_with_odd_stars.count
  end

  def test_in_and_equal
    assert_equal Post.objects.filter(stars: 3).count, Post.objects.filter(stars__in: 3).count
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
    old_posts = Post.objects.filter(created_at__between: [Time.now - 2.months, Time.now - 1.day])
    old_posts_range = Post.objects.filter(created_at__range: [Time.now - 2.months, Time.now - 1.day])
    assert_equal 1, old_posts.count
    assert_equal 1, old_posts_range.count
    assert_equal 'Old post 1', old_posts[0].title
    assert_equal 'Old post 1', old_posts_range[0].title
  end

  def test_date
    today_posts = Post.objects.filter(created_at__date: Date.today)
    assert_equal 5, today_posts.count
  end

  def test_year
    younger_than_1998_year_posts = Post.objects.filter(created_at__year__gt: 1998)
    assert_equal Post.objects.count, younger_than_1998_year_posts.count
    assert_equal 0, Post.objects.filter(created_at__year: 1998).count
  end

  def test_quarter
    # Get a quarter with posts
    quarters = Post.objects.map { |post| (post.created_at.strftime('%m').to_i + 2) / 3 }
    grouped_quarters = quarters.group_by(&:itself)
    quarter = grouped_quarters.keys[0]
    first_quarter = quarter.to_i
    this_quarter_posts = Post.objects.filter(created_at__quarter: first_quarter)
    assert_equal grouped_quarters[quarter].length, this_quarter_posts.count
  end

  def test_month
    this_month_posts = Post.objects.filter(created_at__month: Time.now.utc.month)
    assert_equal 7, this_month_posts.count
  end

  def test_day
    this_day_posts = Post.objects.filter(created_at__day: Time.now.utc.day)
    assert_equal 9, this_day_posts.count
  end

  def test_hour
    this_hour_posts = Post.objects.filter(created_at__hour: Time.now.utc.hour)
    assert_equal 9, this_hour_posts.count
  end

  def test_hour_wrong_lookup
    exception = assert_raises RuntimeError do
      Post.objects.filter(created_at__hour__xx: Time.now.utc.hour)[0]
    end
    assert_equal('Unknown lookup xx', exception.message)
  end

  def test_minute
    this_minute_posts = Post.objects.filter(created_at__minute: Time.now.utc.strftime('%M'))
    assert_equal 9, this_minute_posts.count
  end

  def test_second
    # Get a second with posts
    seconds = Post.objects.map { |post| post.created_at.strftime('%S') }
    grouped_seconds = seconds.group_by(&:itself)
    second = grouped_seconds.keys[0]
    first_second = second.to_i
    this_second_posts = Post.objects.filter(created_at__second: first_second)
    assert_equal grouped_seconds[second].length, this_second_posts.count
  end

  # Check ISO week
  def test_week
    weeks = Post.objects.map { |post| post.created_at.strftime('%V').to_i }
    grouped_weeks = weeks.group_by(&:itself)
    first_week = grouped_weeks.keys[0]
    first_week_int = first_week.to_i
    this_week_posts = Post.objects.filter(created_at__week: first_week_int)
    assert_equal grouped_weeks[first_week].length, this_week_posts.count
  end

  # Check 0-6 (sunday to monday) week day
  def test_weekday
    # Get a week day (0-6, sunday to monday) with posts
    week_days = Post.objects.map { |post| post.created_at.strftime('%w') }
    grouped_week_days = week_days.group_by(&:itself)
    first_week_day = grouped_week_days.keys[0]
    first_week_day_int = first_week_day.to_i
    this_week_day_posts = Post.objects.filter(created_at__week_day: first_week_day_int)
    assert_equal grouped_week_days[first_week_day].length, this_week_day_posts.count
  end

  def test_time
    # Get a time (HH:MM:SS) with posts
    times = Post.objects.map { |post| post.created_at.strftime('%H:%M:%S') }
    grouped_times = times.group_by(&:itself)
    first_time = grouped_times.keys[0]
    this_time_posts = Post.objects.filter(created_at__time: first_time)
    assert_equal grouped_times[first_time].length, this_time_posts.count
  end

  def test_regex
    other_posts = Post.objects.filter(title__regex: /This a post of \d+ stars/).order_by(stars: :ASC)
    if Babik::Database.config[:adapter] == 'sqlite3'
      assert other_posts.sql.select.include?("posts.title REGEXP 'This a post of \\d+ stars'")
      return
    end
    assert_equal 3, other_posts.count
    assert_equal 'This a post of 3 stars', other_posts[0].title
    assert_equal 'This a post of 4 stars', other_posts[1].title
    assert_equal 'This a post of 5 stars', other_posts[2].title
    assert_equal 3, other_posts.count
  end

  def test_iregex
    other_posts = Post.objects.filter(title__iregex: /This a post of \d+ stars/).order_by(stars: :ASC)
    if Babik::Database.config[:adapter] == 'sqlite3'
      assert other_posts.sql.select.include?("posts.title REGEXP '(?i)This a post of \\d+ stars'")
      return
    end
    assert_equal 3, other_posts.count
    assert_equal 'This a post of 3 stars', other_posts[0].title
    assert_equal 'This a post of 4 stars', other_posts[1].title
    assert_equal 'This a post of 5 stars', other_posts[2].title
    assert_equal 3, other_posts.count
  end
end
