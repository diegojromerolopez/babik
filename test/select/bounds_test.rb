# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of first, last, earliest and latest methods
class BoundsTest < Minitest::Test
  def setup
    @cervantes = User.create!(first_name: 'Miguel', last_name: 'De Cervantes y Saavedra')
    Post.create!(title: 'La Galatea', author: @cervantes, stars: 3)
    Post.create!(title: 'La gitanilla', author: @cervantes, stars: 3)
    Post.create!(title: 'El ingenioso hidalgo Don Quijote de La Mancha', author: @cervantes, stars: 5)
    Post.create!(title: 'Rinconete y Cortadillo', author: @cervantes, stars: 4)
  end

  def teardown
    Post.destroy_all
    User.destroy_all
  end

  def test_first_and_earliest
    first_with_less_stars = Post.objects.order_by('stars').first
    earliest_with_less_stars = Post.objects.earliest('stars')
    latest_with_more_stars = Post.objects.latest('-stars')
    assert_equal latest_with_more_stars.id, first_with_less_stars.id
    assert_equal earliest_with_less_stars.id, first_with_less_stars.id
    assert_equal 'La Galatea', first_with_less_stars.title
    assert_equal 'La Galatea', earliest_with_less_stars.title
    assert_equal 3, first_with_less_stars.stars
    assert_equal 3, earliest_with_less_stars.stars
  end

  def test_last_and_latest
    last_with_less_stars = Post.objects.order_by('stars').last
    latest_with_less_stars = Post.objects.latest('stars')
    earliest_with_more_stars = Post.objects.earliest('-stars')
    assert_equal earliest_with_more_stars.id, last_with_less_stars.id
    assert_equal latest_with_less_stars.id, last_with_less_stars.id
    assert_equal 'El ingenioso hidalgo Don Quijote de La Mancha', last_with_less_stars.title
    assert_equal 'El ingenioso hidalgo Don Quijote de La Mancha', latest_with_less_stars.title
    assert_equal 5, last_with_less_stars.stars
    assert_equal 5, latest_with_less_stars.stars
  end
end
