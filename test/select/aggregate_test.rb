# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of aggregate method
class AggregateTest < Minitest::Test

  def setup
    @caesar = User.create!(first_name: 'Julius', last_name: 'Caesar', email: 'backstabbed@example.com')
    (1..7).each do |book_i|
      post = Post.create!(title: "Commentarii de Bello Gallico #{book_i}", author: @caesar, stars: [book_i, 5].min)
      post.add_tag(Tag.first_or_create!(name: 'war'))
      post.add_tag(Tag.first_or_create!(name: 'gallic'))
      post.add_tag(Tag.first_or_create!(name: 'tribes'))
      post.add_tag(Tag.first_or_create!(name: 'victory'))
      post.add_tag(Tag.first_or_create!(name: 'campaign'))
    end

    @aulus = User.create!(first_name: 'Aulus', last_name: 'Hirtius', email: 'aulushirtius@example.com')
    last_post = Post.create!(title: 'Commentarii de Bello Gallico 8', author: @aulus)
    last_post.add_tag(Tag.first_or_create!(name: 'war'))
    last_post.add_tag(Tag.first_or_create!(name: 'last_book'))
  end

  def teardown
    Post.destroy_all
    User.destroy_all
  end

  def test_local_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = @caesar
                             .objects(:posts)
                             .aggregate(avg_stars: Babik.agg(:avg, 'stars'))
    assert_equal avg_stars, avg_starts_aggregation[:avg_stars]
  end

  def test_foreign_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = User
                             .objects
                             .filter(id: @caesar.id)
                             .aggregate(avg_stars: Babik.agg(:avg, 'posts::stars'))
    assert_equal avg_stars, avg_starts_aggregation[:avg_stars]
  end

  def test_simplified_foreign_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = @caesar
                             .objects
                             .aggregate(avg_stars: Babik.agg(:avg, 'posts::stars'))
    assert_equal avg_stars, avg_starts_aggregation[:avg_stars]
  end

  def test_max
    max_stars = @caesar.objects(:posts).map(&:stars).max
    assert_equal max_stars, @caesar.objects(:posts).aggregate(max_stars: Babik.agg(:max, 'stars'))[:max_stars]
  end

  def test_min
    min_stars = @caesar.objects(:posts).map(&:stars).min
    assert_equal min_stars, @caesar.objects(:posts).aggregate(min_stars: Babik::Min.new('stars'))[:min_stars]
  end

  def test_sum
    sum_stars = @caesar.objects(:posts).map(&:stars).inject(:+)
    assert_equal sum_stars, @caesar.objects(:posts).aggregate(sum_stars: Babik::Sum.new('stars'))[:sum_stars]
  end


end
