# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of filter method
class FilterTest < Minitest::Test
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

    first_post = Post.create!(author: @pelayo, title: 'I\'m not an ass', category: @main_category)
    second_post = Post.create!(author: @pelayo, title: 'Come and get my land', category: @main_category)

    first_post.tags << battle
    first_post.tags << asturias
    first_post.tags << victory

    second_post.tags << asturias
    second_post.tags << victory
  end

  def teardown
    User.destroy_all
    GeoZone.destroy_all
    Post.destroy_all
    BadPost.destroy_all
    Tag.destroy_all
    Category.destroy_all
  end

  def test_local_filter
    kings = User.objects.filter(first_name__endswith: 'I').order_by(%i[first_name ASC])
    asturian_kings = ['Alfonso I', 'Fruela I']
    user_count = 0
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
      user_count += 1
    end
    assert_equal asturian_kings.count, user_count
  end

  def test_local_or_filter
    kings = User.objects
                .filter([{ first_name: 'Pelayo' }, { last_name: 'Católico' }])
                .order_by(%i[first_name ASC])
    asturian_kings = ['Alfonso I', 'Pelayo']
    user_count = 0
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
      user_count += 1
    end
    assert_equal asturian_kings.count, user_count
  end

  def test_foreign_filter
    kings = User.objects
                .filter('zone::parent_zone::name': 'Asturias')
                .order_by(%i[first_name ASC])
    asturian_kings = ['Favila', 'Fruela I', 'Pelayo']
    user_count = 0
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
      user_count += 1
    end
    assert_equal asturian_kings.count, user_count
  end

  def test_foreign_filter_by_active_record_object
    kings = User.objects
                .filter('zone::parent_zone': @asturias)
                .order_by(%i[first_name ASC])
    asturian_kings = ['Favila', 'Fruela I', 'Pelayo']
    user_count = 0
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
      user_count += 1
    end
    assert_equal asturian_kings.count, user_count
  end

  def test_foreign_or_filter
    kings = User.objects
                .filter([{ first_name: 'Pelayo' }, { 'zone::name': 'Cantabria' }])
                .order_by(%i[first_name ASC])
    asturian_kings = ['Alfonso I', 'Pelayo']
    user_count = 0
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
      user_count += 1
    end
    assert_equal asturian_kings.count, user_count
  end

  # Different ways of querying with in lookup
  def test_foreign_in
    first_users = [
      User.objects.filter(zone: [@cangas_de_onis, @cantabria]).order_by(created_at: :ASC)[0],
      User.objects.filter(zone_id__in: [@cangas_de_onis, @cantabria]).order_by(created_at: :ASC)[0],
      User.objects.filter(zone__in: [@cangas_de_onis, @cantabria]).order_by(created_at: :ASC)[0],
      User.objects.filter(zone: [@cangas_de_onis.id, @cantabria.id]).order_by(created_at: :ASC)[0],
      User.objects.filter(zone__in: [@cangas_de_onis.id, @cantabria.id]).order_by(created_at: :ASC)[0]
    ]
    different_user_ids = Set.new(first_users.map(&:id))
    assert_equal 1, different_user_ids.length
  end

  def test_many_to_many_foreign_filter
    tags = Tag.objects.distinct.filter('posts::title__contains': 'an ass').order_by(%i[name ASC])
    tag_names = %w[asturias battle victory]
    tag_count = 0
    tags.each_with_index do |tag, tag_index|
      assert_equal tag_names[tag_index], tag.name
      tag_count += 1
    end
    assert_equal tag_names.count, tag_count
  end

  def test_deep_many_to_many_foreign_filter
    tags = Tag.objects.distinct.filter('posts::category::name': 'Dialogues').order_by(%i[name ASC])
    tag_names = %w[asturias battle victory]
    tag_count = 0
    tags.each_with_index do |tag, tag_index|
      assert_equal tag_names[tag_index], tag.name
      tag_count += 1
    end
    assert_equal tag_names.count, tag_count
  end

  def test_several_foreign_filters
    cangueses_called_pelayo = User.objects.distinct.filter(
      first_name: 'Pelayo', 'zone::name': @cangas_de_onis.name, 'posts::tags::name': 'asturias'
    )
    assert_equal 1, cangueses_called_pelayo.count
    assert_equal @pelayo.id, cangueses_called_pelayo.first.id
  end

  def test_foreign_filter_by_object
    cangueses = User.objects.distinct.filter(zone: @cangas_de_onis).order_by(%i[first_name ASC])
    names = ['Favila', 'Fruela I', 'Pelayo']
    cangueses.each_with_index do |cangues, cangues_index|
      assert_equal names[cangues_index], cangues.first_name
    end
    assert_equal names.length, cangueses.count
  end

  def test_wrong_local_filter
    exception = assert_raises RuntimeError do
      User.objects.filter(this_local_field_does_not_exists: 'whatever').all
    end
    assert_equal(
      'Unrecognized field this_local_field_does_not_exists for model User in filter/exclude', exception.message
    )
  end

  def test_wrong_many_to_many_foreign_filter
    exception = assert_raises RuntimeError do
      BadTag.objects.distinct.filter('posts::category::name': 'Dialogues').order_by(%i[name ASC])
    end
    assert_equal('Relationship posts is has_and_belongs_to_many. Convert it to has_many-through', exception.message)
  end

  def test_wrong_association_in_foreign_filter
    exception = assert_raises RuntimeError do
      Tag.objects.filter('posts::bad_association::name': 'Dialogues').order_by(%i[name ASC])
    end
    assert_equal(
      'Bad selection path: \
posts::bad_association::name. bad_association not found in model Post when filtering Tag objects',
      exception.message
    )
  end

  def test_wrong_field_name_of_foreign_model
    exception = assert_raises RuntimeError do
      Tag.objects.filter('posts::category::xxx': 'Dialogues').order_by(%i[name ASC])
    end
    assert_equal(
      'Unrecognized field xxx for model Category in filter/exclude',
      exception.message
    )
  end

  def test_wrong_parameter_passed_to_filter
    exception = assert_raises RuntimeError do
      Tag.objects.filter('INVALID VALUE').order_by(%i[name ASC])
    end
    assert_equal(
      '`filter\' parameter must be an Array for OR-based AND-conditions or a hash for a lone AND-condition',
      exception.message
    )
  end
end
