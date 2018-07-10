# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Select related method test
class SelectRelatedTest < Minitest::Test

  def setup
    @baetica = GeoZone.create!(name: 'Baetica')
    @corduba = GeoZone.create!(name: 'Corduba', parent_zone: @baetica)
    @seneca_sr = User.create!(first_name: 'Marcus Annaeus', last_name: 'Seneca', zone: @corduba)
    @seneca_jr = User.create!(first_name: 'Lucius Annaeus', last_name: 'Seneca', zone: @corduba)

    @africa = GeoZone.create!(name: 'Africa')
    @cartago = GeoZone.create!(name: 'Cartago', parent_zone: @africa)
    @tertullianus = User.create!(first_name: 'Quintus Septimius', last_name: 'Florens Tertullianus', zone: @cartago)

    short_stories = Category.create(name: 'Short stories')
    legal = Category.create(name: 'Legal texts')
    oratory = Category.create(name: 'Oratory')
    Post.create!(title: 'Gesta Romanorum', author: @seneca_sr, category: short_stories)
    Post.create!(title: 'Controversiae', author: @seneca_sr, category: legal)
    Post.create!(title: 'Suasoriae', author: @seneca_sr, category: oratory)

    stoic_texts = Category.create(name: 'Stoic texts')
    Post.create!(title: 'De brevitate vitae', author: @seneca_jr, category: stoic_texts)
    Post.create!(title: 'Epistulae Morales ad Lucilium', author: @seneca_jr, category: stoic_texts)
    Post.create!(title: 'De tranquillitate animi', author: @seneca_jr, category: stoic_texts)
  end

  def teardown
    GeoZone.destroy_all
    User.destroy_all
    Category.destroy_all
    Post.destroy_all
  end

  def test_select_related
    users = User.objects.order_by('first_name')
    number_of_users = User.objects.count
    number_of_returned_users = 0
    User
      .objects
      .select_related(:zone)
      .order_by('first_name')
      .each_with_index do |user_with_related, user_with_related_index|
      # Loop through each user with his/her related objects
      user, select_related = user_with_related
      # User tests
      expected_user = users[user_with_related_index]
      assert_equal User, user.class
      assert_equal expected_user.id, user.id
      assert_equal expected_user, user
      # Zone tests
      expected_zone = expected_user.zone
      assert_equal GeoZone, select_related[:zone].class
      assert_equal user.zone_id, select_related[:zone].id
      assert_equal expected_zone, select_related[:zone]
      # Users count
      number_of_returned_users += 1
    end
    assert_equal number_of_users, number_of_returned_users
  end

  def test_select_related_several_associations
    expected_posts = Post.objects.filter(author: @seneca_sr).order_by(title: :DESC)
    posts = Post.objects
                .filter(author: @seneca_sr)
                .order_by(title: :DESC)
                .select_related([:author, :category])
    _test_select_related_posts(expected_posts, posts)
  end

  def test_select_related_several_associations_from_instance
    expected_posts = Post.objects.filter(author: @seneca_sr).order_by(title: :DESC)
    posts = @seneca_sr.objects(:posts)
                      .order_by(title: :DESC)
                      .select_related([:author, :category])
    _test_select_related_posts(expected_posts, posts)
  end

  def _test_select_related_posts(expected_posts, posts)
    # Load the posts with 4 or more stars with their author and category
    posts.each_with_index do |post_with_author_category, index|
      # Load post and its two associated objects
      post, foreign_objects = post_with_author_category
      author = foreign_objects[:author]
      category = foreign_objects[:category]
      # Check post
      expected_post = expected_posts[index]
      assert_equal Post, post.class
      assert_equal expected_post.id, post.id
      assert_equal expected_post, post
      # Check author (user)
      assert_equal User, author.class
      assert_equal post.author_id, author.id
      assert_equal post.author, author
      # Check category
      assert_equal Category, category.class
      assert_equal post.category_id, category.id
      assert_equal post.category, category
    end
  end



end