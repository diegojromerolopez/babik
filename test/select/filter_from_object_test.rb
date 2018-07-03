# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of filter method when being called from an ActiveRecord object
class FilterFromObjectTest < Minitest::Test

  def setup
    @asturias = GeoZone.new(name: 'Asturias')
    @cantabria = GeoZone.new(name: 'Cantabria')
    @cangas_de_onis = GeoZone.new(name: 'Cangas de Onís', parent_zone: @asturias)

    @pelayo = User.create!(first_name: 'Pelayo', zone: @cangas_de_onis)
    User.create!(first_name: 'Favila', zone: @cangas_de_onis)
    User.create!(first_name: 'Alfonso I', last_name: 'Católico', zone: @cantabria)
    User.create!(first_name: 'Fruela I', zone: @cangas_de_onis)

    battle = Tag.create!(name: 'battle')
    asturias = Tag.create!(name: 'asturias')
    victory = Tag.create!(name: 'victory')
    Tag.create!(name: 'chronicle')

    @main_category = Category.create!(name: 'Dialogues')
    @other_category = Category.create!(name: 'My reign')

    @first_post = Post.create!(author: @pelayo, title: 'I\'m not an ass', category: @main_category)
    @second_post = Post.create!(author: @pelayo, title: 'Come and get my land', category: @main_category)
    @third_post = Post.create!(author: @pelayo, title: 'Will keep my kingdom', category: @other_category)

    @first_post.tags << battle
    @first_post.tags << asturias
    @first_post.tags << victory
    @second_post.tags << asturias
    @second_post.tags << victory
  end

  def teardown
    User.destroy_all
    GeoZone.destroy_all
    Post.destroy_all
    Tag.destroy_all
    Category.destroy_all
  end

  def test_belongs_to_or_has_one
    # Returns an ActiveRecord object
    pelayo_zone = @pelayo.objects(:zone)
    assert_equal @cangas_de_onis.class, pelayo_zone.class
    assert_equal @cangas_de_onis.id, pelayo_zone.id
  end

  def test_direct_has_many_explicit_foreign_key
    # Direct has_many relationship with an explicit foreign_key
    users_from_cangas_de_onis = @cangas_de_onis.objects(:users).order_by(first_name: :ASC)
    assert_equal @cangas_de_onis.users.count, users_from_cangas_de_onis.count
    first_names = ['Favila', 'Fruela I', 'Pelayo']
    users_count = 0
    users_from_cangas_de_onis.each_with_index do |user, user_index|
      assert_equal first_names[user_index], user.first_name
      users_count += 1
    end
    assert_equal first_names.count, users_count
  end

  def test_deep_has_many
    # Deep has_many relationship
    tags_from_cangas_de_onis = @cangas_de_onis
                               .objects(:'users::posts::tags')
                               .distinct
                               .exclude(name: 'asturias')
                               .order_by(name: :ASC)
    tag_names = %w[battle victory]
    tags_count = 0
    tags_from_cangas_de_onis.each_with_index do |tag, tag_index|
      assert_equal tag_names[tag_index], tag.name
      tags_count += 1
    end
    assert_equal tag_names.count, tags_count
  end

  def test_direct_has_many
    # Direct has_many relationship
    main_category_posts = @main_category.objects(:posts).order_by(created_at: :ASC)
    posts = @main_category.posts
    assert_equal posts.count, main_category_posts.count
    post_titles = [@first_post.title, @second_post.title]
    post_count = 0
    main_category_posts.each_with_index do |post, post_index|
      assert_equal post_titles[post_index], post.title
      post_count += 1
    end
    assert_equal post_titles.count, post_count
  end

  def test_through_has_many_1
    # has_many through relationship
    assert_equal 5, @pelayo.objects('posts::tags').count
    assert_equal 3, @pelayo.objects('posts::tags').distinct.count
    tag_names = %w[asturias battle victory]
    tag_count = 0
    @pelayo.objects('posts::tags').distinct.order_by(name: :ASC).each_with_index do |tag, tag_index|
      assert_equal tag_names[tag_index], tag.name
      tag_count += 1
    end
    assert_equal tag_names.count, tag_count
  end

  def test_through_has_many_2
    main_distinct_tags = @main_category.objects('posts::tags').distinct.order_by(name: :ASC)
    main_tags = @main_category.objects('posts::tags').order_by(name: :ASC)

    assert_equal 3, main_distinct_tags.count
    assert_equal 5, main_tags.count

    tag_names = %w[asturias battle victory]
    tag_count = 0
    main_distinct_tags.each_with_index do |tag, tag_index|
      assert_equal tag_names[tag_index], tag.name
      tag_count += 1
    end
    assert_equal main_distinct_tags.count, tag_count
  end

end