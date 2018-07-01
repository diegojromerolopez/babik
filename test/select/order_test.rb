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

  def test_basic_order
    users = User.objects.filter('zone::name': 'Hispania').order_by(%i[first_name ASC])
    goth_king_names = [
      'Alarico I', 'Alarico II', 'Ataulfo', 'Eurico', 'Sigerico', 'Teodorico I', 'Teodorico II', 'Turismundo'
    ]
    users.each_with_index do |user, user_index|
      assert_equal goth_king_names[user_index], user.first_name
    end
  end

  def test_deep_order
    users = User.objects.order_by(%i[zone::name ASC], %i[first_name ASC])
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
  end

  def test_wrong_order
    exception = assert_raises RuntimeError do
      User.objects.filter('zone::name': 'Hispania').order_by([:first_name, 'XXXX'])
    end
    assert_equal('Invalid order type for QuerySet.order_by: order_by_list. Expecting an array [<field>: :ASC|:DESC]', exception.message)
  end

  def test_wrong_order_param_type
    exception = assert_raises RuntimeError do
      User.objects.filter('zone::name': 'Hispania').order_by(2222)
    end
    assert_equal('Invalid value for QuerySet.order_by: order_by_list. Expecting an array [<field>: :ASC|:DESC]', exception.message)
  end

end