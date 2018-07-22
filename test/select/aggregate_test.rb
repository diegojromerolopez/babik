# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of aggregate method
class AggregateTest < Minitest::Test

  def setup
    @caesar = User.create!(first_name: 'Julius', last_name: 'Caesar', email: 'backstabbed@example.com')
    (1..7).each do |book_i|
      post = Post.create!(title: "Commentarii de Bello Gallico #{book_i}", author: @caesar, stars: [book_i, 5].min)
      post.add_tag_by_name('war')
      post.add_tag_by_name('gallic')
      post.add_tag_by_name('tribes')
      post.add_tag_by_name('victory')
      post.add_tag_by_name('campaign')
      post.add_tag_by_name('biography')
    end

    @aulus = User.create!(first_name: 'Aulus', last_name: 'Hirtius', email: 'aulushirtius@example.com')
    last_post = Post.create!(title: 'Commentarii de Bello Gallico 8', author: @aulus)
    last_post.add_tag_by_name('war')
    last_post.add_tag_by_name('last_book')
  end

  def teardown
    Tag.destroy_all
    Post.destroy_all
    User.destroy_all
  end

  def test_local_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = @caesar
                             .objects(:posts)
                             .aggregate(avg_stars: Babik::QuerySet.agg(:avg, 'stars'))
    assert_equal avg_stars.round(4), avg_starts_aggregation[:avg_stars].round(4)
  end

  def test_foreign_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = User
                             .objects
                             .filter(id: @caesar.id)
                             .aggregate(avg_stars: Babik::QuerySet.agg(:avg, 'posts::stars'))
    assert_equal avg_stars.round(4), avg_starts_aggregation[:avg_stars].round(4)
  end

  def test_simplified_foreign_avg
    stars = @caesar.objects(:posts).map(&:stars)
    avg_stars = stars.reduce(:+) / stars.length.to_f
    avg_starts_aggregation = @caesar
                             .objects
                             .aggregate(avg_stars: Babik::QuerySet.agg(:avg, 'posts::stars'))
    assert_equal avg_stars.round(4), avg_starts_aggregation[:avg_stars].round(4)
  end

  def test_local_distinct_count
    # Julius Caesar has all types of value of stars
    # As he has posts with all stars, it should be 5
    count_aggregation = @caesar
                        .objects
                        .project(:stars)
                        .aggregate(
                          caesar_count_distinct_stars:
                            Babik::QuerySet.agg(:count_distinct, 'posts::stars')
                        )
    assert_equal 5, count_aggregation[:caesar_count_distinct_stars]
  end

  def test_foreign_distinct_count
    # Julius Caesar has 6 tags in his posts, it should be 6
    count_aggregation = @caesar
                        .objects
                        .aggregate(
                          caesar_count_distinct_tags:
                            Babik::QuerySet.agg(:count_distinct, 'posts::tags::id')
                        )
    assert_equal 6, count_aggregation[:caesar_count_distinct_tags]
  end

  def test_foreign_count
    # Julius Caesar has 6 tags in his posts, it should be 6
    count_aggregation = @caesar
                        .objects
                        .aggregate(
                          caesar_count_tags:
                            Babik::QuerySet.agg(:count, 'posts::tags::id')
                        )
    assert_equal @caesar.objects(:posts).count * 6, count_aggregation[:caesar_count_tags]
  end

  def test_max
    max_stars = @caesar.objects(:posts).map(&:stars).max
    max_stars_agg = @caesar.objects(:posts)
                           .aggregate(max_stars: Babik::QuerySet.agg(:max, 'stars'))[:max_stars]
    assert_equal max_stars, max_stars_agg
  end

  def test_min
    min_stars = @caesar.objects(:posts).map(&:stars).min
    min_stars_agg = @caesar.objects(:posts)
                           .aggregate(min_stars: Babik::QuerySet::Min.new('stars'))[:min_stars]
    assert_equal min_stars, min_stars_agg
  end

  def test_sum
    sum_stars = @caesar.objects(:posts).map(&:stars).inject(:+)
    sum_stars_agg = @caesar.objects(:posts)
                           .aggregate(sum_stars: Babik::QuerySet::Sum.new('stars'))[:sum_stars]
    assert_equal sum_stars, sum_stars_agg
  end

  def test_sum_max_min
    sum_stars = @caesar.objects(:posts).map(&:stars).inject(:+)
    max_stars = @caesar.objects(:posts).map(&:stars).max
    min_stars = @caesar.objects(:posts).map(&:stars).min


    max_min_stars_agg = @caesar.objects(:posts)
                               .aggregate(
                                 sum_stars: Babik::QuerySet::Sum.new('stars'),
                                 max_stars: Babik::QuerySet::Max.new('stars'),
                                 min_stars: Babik::QuerySet::Min.new('stars')
                               )
    assert_equal sum_stars, max_min_stars_agg[:sum_stars]
    assert_equal max_stars, max_min_stars_agg[:max_stars]
    assert_equal min_stars, max_min_stars_agg[:min_stars]
  end

  def test_std_dev
    if %w[postgres, mysql2].include?(Babik::Database.config[:adapter])
      std_dev_var_agg = @caesar.objects(:posts)
                               .aggregate(
                                 std_dev_stars: Babik::QuerySet::StdDev.new('stars'),
                                 std_dev_sample_stars: Babik::QuerySet::StdDevSample.new('stars'),
                                 var_stars: Babik::QuerySet::Var.new('stars'),
                                 var_sample_stars: Babik::QuerySet::VarSample.new('stars'),
                               )

      assert_in_delta 1.4982983545287878, std_dev_var_agg[:std_dev_stars]
      assert_in_delta 1.618347187425374, std_dev_var_agg[:std_dev_sample_stars]
      assert_in_delta 2.2448979591836733, std_dev_var_agg[:var_stars]
      assert_in_delta 2.244897959183673, std_dev_var_agg[:var_sample_stars]
    end
  end

end
