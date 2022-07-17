# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Ordering tests
class OrderTest < Minitest::Test
  def setup
    @frankish_kingdom = GeoZone.create!(name: 'Frankish Kingdom')

    frankish_king_names = [
      'Merovech',
      'Childeric I',
      'Clovis I'
    ]

    @frankish_kings = []
    frankish_king_names.each do |frankish_king|
      @frankish_kings << User.create!(first_name: frankish_king, last_name: 'Merovingian', zone: @frankish_kingdom)
    end

    @hispania = GeoZone.create!(name: 'Hispania')
    goth_king_names = ['Alarico I',
                       'Ataulfo',
                       'Sigerico',
                       'Teodorico I',
                       'Turismundo',
                       'Teodorico II',
                       'Eurico',
                       'Alarico II']

    @goth_kings = []
    goth_king_names.each do |goth_king|
      @goth_kings << User.create!(first_name: goth_king, zone: @hispania)
    end
  end

  def teardown
    User.destroy_all
    GeoZone.destroy_all
  end

  def test_first
    first_user = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name ASC]).first
    assert_equal 'Alarico I', first_user.first_name
  end

  def test_last_asc
    last_user = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name ASC]).last
    assert_equal 'Turismundo', last_user.first_name
  end

  def test_last_desc
    last_user = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name DESC]).last
    assert_equal 'Alarico I', last_user.first_name
  end

  def test_first_last
    first = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name ASC]).first
    inverted_last = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name DESC]).last
    assert_equal first.id, inverted_last.id
    assert_equal first.first_name, inverted_last.first_name
  end

  def test_basic_order
    users = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name ASC])
    _test_basic_order(users)
  end

  def test_basic_order_hash
    users = User.objects.filter('zone::name': 'Hispania').order_by(first_name: :ASC)
    _test_basic_order(users)
  end

  def test_basic_order_string
    users = User.objects.filter('zone::name': 'Hispania').order_by('first_name')
    _test_basic_order(users)
  end

  def test_basic_order_symbol
    users = User.objects.filter('zone::name': 'Hispania').order_by(:first_name)
    _test_basic_order(users)
  end

  def _test_basic_order(users)
    goth_king_names = [
      'Alarico I', 'Alarico II', 'Ataulfo', 'Eurico', 'Sigerico', 'Teodorico I', 'Teodorico II', 'Turismundo'
    ]
    users.each_with_index do |user, user_index|
      assert_equal goth_king_names[user_index], user.first_name
    end
    assert users.ordered?
  end

  def test_deep_order
    users = User.objects.order_by(%i[zone::name ASC], %i[first_name ASC])
    reversed_users = users.reverse
    king_names = [
      'Childeric I',
      'Clovis I',
      'Merovech',
      'Alarico I',
      'Alarico II',
      'Ataulfo',
      'Eurico',
      'Sigerico',
      'Teodorico I',
      'Teodorico II',
      'Turismundo'
    ]
    users.each_with_index do |user, user_index|
      assert_equal king_names[user_index], user.first_name
    end
    assert users.ordered?

    reversed_king_names = king_names.reverse
    reversed_users.each_with_index do |reversed_order_user, user_index|
      assert_equal reversed_king_names[user_index], reversed_order_user.first_name
    end
    assert reversed_users.ordered?

    king_names.each_with_index do |king_name, king_index|
      assert_equal king_name, users[king_index].first_name
      assert_equal king_name, reversed_users[king_names.length - king_index - 1].first_name
    end
  end

  def test_disorder
    users = User.objects.order_by(%i[zone::name ASC], %i[first_name ASC])
    users.disorder!
    refute users.ordered?
  end

  def test_order_with_prefixed_direction
    users = User.objects.order_by('-zone::name', '-first_name')
    first_user = users.first
    assert_equal 'Hispania', first_user.zone.name
    assert_equal 'Turismundo', first_user.first_name
  end

  def test_wrong_order
    exception = assert_raises RuntimeError do
      User.objects.filter('zone::name': 'Hispania').order_by([:first_name, 'XXXX'])
    end
    assert_equal('Invalid order type XXXX in first_name: Expecting :ASC or :DESC', exception.message)
  end

  def test_wrong_order_param_type
    exception = assert_raises RuntimeError do
      User.objects.filter('zone::name': 'Hispania').order_by(2222)
    end
    assert_equal('Invalid type of order: 2222', exception.message)
  end

  def test_wrong_field_path
    exception = assert_raises RuntimeError do
      User.objects.filter('zone::name': 'Hispania').order_by([1111, :ASC])
    end
    assert_equal('field_path of class Integer not valid. A Symbol/String/Babik::Selection::Base expected',
                 exception.message)
  end
end
