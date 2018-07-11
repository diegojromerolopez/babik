# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Subquery test
class SubqueryTest < Minitest::Test

  def setup
    @baetica = GeoZone.create!(name: 'Baetica')
    @corduba = GeoZone.create!(name: 'Corduba', parent_zone: @baetica)
    @seneca_sr = User.create!(first_name: 'Marcus Annaeus', last_name: 'Seneca', zone: @corduba)
    short_stories = Category.create(name: 'Short stories')
    legal = Category.create(name: 'Legal texts')
    oratory = Category.create(name: 'Oratory')
    Post.create!(title: 'Gesta Romanorum', author: @seneca_sr, category: short_stories)
    Post.create!(title: 'Controversiae', author: @seneca_sr, category: legal)
    Post.create!(title: 'Suasoriae', author: @seneca_sr, category: oratory)
  end

  def teardown
    GeoZone.destroy_all
    User.destroy_all
    Category.destroy_all
    Post.destroy_all
  end

  def test_subquery_with_equal
    seneca_sr_posts = Post.objects.filter(id: @seneca_sr.objects(:posts).project(:id))
    assert_equal @seneca_sr.objects(:posts).count, seneca_sr_posts.count
    seneca_sr_posts_count = 0
    seneca_sr_posts.each do |post|
      assert_equal @seneca_sr.id, post.author_id
      seneca_sr_posts_count += 1
    end
    assert_equal seneca_sr_posts_count, seneca_sr_posts.count
  end

  def test_subquery_with_in
    seneca_sr_posts = Post.objects.filter(id__in: @seneca_sr.objects(:posts).project(:id))
    assert_equal @seneca_sr.objects(:posts).count, seneca_sr_posts.count
    seneca_sr_posts_count = 0
    seneca_sr_posts.each do |post|
      assert_equal @seneca_sr.id, post.author_id
      seneca_sr_posts_count += 1
    end
    assert_equal seneca_sr_posts_count, seneca_sr_posts.count
  end

end