# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require_relative 'delete_test'

# Tests of delete with foreign conditions method
class ForeignConditionsDeleteTest < DeleteTest

  def test_delete_from_model
    Post.objects.filter('author::first_name': 'Aulus').delete
    assert_equal 0, Post.objects.filter('author::first_name': 'Aulus').count
    assert_equal false, Post.objects.filter('author::first_name': 'Aulus').exists?
    assert_equal 0, @aulus.objects(:posts).count
    assert_equal false, @aulus.objects(:posts).exists?
  end

  def test_delete_from_instance
    @aulus.objects(:posts).delete
    assert_equal 0, Post.objects.filter('author::first_name': 'Aulus').count
    assert_equal false, Post.objects.filter('author::first_name': 'Aulus').exists?
    assert_equal 0, @aulus.objects(:posts).count
    assert_equal false, @aulus.objects(:posts).exists?
  end

  def test_delete_from_model_deep_conditions
    Tag.objects.filter('posts::author::first_name': 'Aulus').delete
    assert_equal 0, Tag.objects.filter('posts::author::first_name': 'Aulus').count
    assert_equal false, Tag.objects.filter('posts::author::first_name': 'Aulus').exists?
    assert_equal 0, @aulus.objects('posts::tags').count
    assert_equal false, @aulus.objects('posts::tags').exists?
  end

  def test_delete_from_instance_deep_condition_not_matched
    @aulus.objects('posts::tags').filter(name: 'not existing tag').delete
    assert_equal 3, Tag.objects.filter('posts::author::first_name': 'Aulus').count
    assert_equal true, Tag.objects.filter('posts::author::first_name': 'Aulus').exists?
    assert_equal 3, @aulus.objects('posts::tags').count
    assert_equal true, @aulus.objects('posts::tags').exists?
  end

  def test_delete_from_instance_deep_conditions
    tag_to_delete = 'last_book'
    @aulus.objects('posts::tags').filter(name: tag_to_delete).delete
    assert_equal 2, Tag.objects.filter('posts::author::first_name': 'Aulus').count
    assert_equal true, Tag.objects.filter('posts::author::first_name': 'Aulus').exists?
    Tag.objects.filter('posts::author::first_name': 'Aulus').each do |aulus_tag|
      refute_equal tag_to_delete, aulus_tag.name
    end
    assert_equal 2, @aulus.objects('posts::tags').count
    assert_equal true, @aulus.objects('posts::tags').exists?
    @aulus.objects('posts::tags').each do |aulus_tag|
      refute_equal tag_to_delete, aulus_tag.name
    end
  end

end
