# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Class for Tests of update method
class UpdateTest < Minitest::Test

  def setup
    @castille = GeoZone.create!(name: 'Castilla')
    @leon = GeoZone.create!(name: 'León')
    @burgos = GeoZone.create!(name: 'Burgos', parent_zone: @castille)
    @cid = User.create!(first_name: 'Rodrigo', last_name: 'Díaz de Vivar', zone: @burgos)
    @jimena = User.create!(first_name: 'Jimena', last_name: 'Díaz', zone: @burgos)
    @alfonso_vi = User.create!(first_name: 'Alfonso VI', last_name: 'de León', zone: @leon)

    Post.create!(author: @cid, title: 'Cantar del Mío Cid', stars: 4)
    Post.create!(author: @cid, title: 'Mocedades del Cid', stars: 3)
  end

  def teardown
    GeoZone.destroy_all
    User.destroy_all
    Post.destroy_all
  end

  def test_update_local_conditions
    User.objects.filter(first_name: 'Rodrigo').update(first_name: 'Cid')
    assert_equal 0, User.objects.filter(first_name: 'Rodrigo').count
    assert_equal 1, User.objects.filter(first_name: 'Cid').count
    assert_equal @cid.id, User.objects.get(first_name: 'Cid').id
  end

  def test_increment_field_with_local_conditions
    @cid
      .objects(:posts)
      .filter(title__startswith: 'Cantar')
      .update(stars: Babik::QuerySet::Update::Assignment::Increment.new('stars'))
    assert_equal 5, Post.objects.get(title: 'Cantar del Mío Cid').stars
    assert_equal 3, Post.objects.get(title: 'Mocedades del Cid').stars
  end

  def test_decrement_field_with_local_conditions
    @cid
      .objects(:posts)
      .filter(title__startswith: 'Cantar')
      .update(stars: Babik::QuerySet::Update::Assignment::Decrement.new('stars'))
    assert_equal 3, Post.objects.get(title: 'Cantar del Mío Cid').stars
    assert_equal 3, Post.objects.get(title: 'Mocedades del Cid').stars
  end

  def test_multiply_field_with_local_conditions
    @cid
      .objects(:posts)
      .filter(title__startswith: 'Cantar')
      .update(stars: Babik::QuerySet::Update::Assignment::Multiply.new('stars', 2))
    assert_equal 8, Post.objects.get(title: 'Cantar del Mío Cid').stars
    assert_equal 3, Post.objects.get(title: 'Mocedades del Cid').stars
  end

  def test_divide_field_with_local_conditions
    @cid
      .objects(:posts)
      .filter(title__startswith: 'Cantar')
      .update(stars: Babik::QuerySet::Update::Assignment::Divide.new('stars', 2))
    assert_equal 2, Post.objects.get(title: 'Cantar del Mío Cid').stars
    assert_equal 3, Post.objects.get(title: 'Mocedades del Cid').stars
  end

  def test_apply_function_to_field_with_local_conditions
    @cid
      .objects(:posts)
      .filter(title__startswith: 'Cantar')
      .update(stars: Babik::QuerySet::Update::Assignment::Function.new('stars', 'LENGTH(title)'))
    assert_equal 'Cantar del Mío Cid'.length, Post.objects.get(title: 'Cantar del Mío Cid').stars
    assert_equal 3, Post.objects.get(title: 'Mocedades del Cid').stars
  end

  def test_update_foreign_conditions
    User.objects.filter('zone::name': 'Burgos').update(zone_id: @castille.id)
    assert_equal 0, User.objects.filter(zone: @burgos).count
    assert_equal 2, User.objects.filter(zone: @castille).count
  end

  def test_update_foreign_conditions_by_association_name
    User.objects.filter('zone::name': 'Burgos').update(zone: @castille)
    assert_equal 0, User.objects.filter(zone: @burgos).count
    assert_equal 2, User.objects.filter(zone: @castille).count
  end

end