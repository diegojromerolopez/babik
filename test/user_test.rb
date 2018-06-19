# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

class UserTest < Minitest::Test

  def setup
    @rome = GeoZone.create!(name: 'Rome')
    @jerusalem = GeoZone.create!(name: 'Jerusalem')

    @tiberius = User.create!(first_name: 'Tiberius', email: 'tiberius@example.com', zone: @rome)
    @pilate = User.create!(first_name: 'Pontius', last_name: 'Pilate', email: 'pontious@example.com', zone: @jerusalem)
    @flavio = User.create!(first_name: 'Flavio', last_name: 'Josefo', email: 'flaviojosefo@example.com', zone: @jerusalem)
  end

  def teardown
    @rome.destroy
    @jerusalem.destroy
    @tiberius.destroy
    @pilate.destroy
    @flavio.destroy
  end

  # Test the count is well implemented when the returned value is 0
  def test_count_0
    zone_non_existant_description = 'This description does not appear in any zone'
    queryset = User.objects.filter(
      first_name: 'Flavio',
      last_name: 'Josefo',
      "zone::name__different": 'Rome',
      "zone::description": zone_non_existant_description
               )
    active_record_set = User
                        .joins(:zone)
                        .where(first_name: 'Flavio', last_name: 'Josefo', "geo_zones.description": zone_non_existant_description)
                        .where.not("geo_zones.name": 'Rome')
    assert_equal queryset.count, active_record_set.count
    assert_equal queryset.count, queryset.length
    assert queryset.empty?
    assert_equal queryset.exists?, false
  end

  def test_count_1
    queryset = User.objects.filter(
      first_name: 'Flavio',
      last_name: 'Josefo',
      "zone::name__different": 'Madrid'
    )
    active_record_set = User
                        .joins(:zone)
                        .where(first_name: 'Flavio', last_name: 'Josefo')
                        .where.not("geo_zones.name": 'Madrid')
    assert_equal queryset.count, active_record_set.count
    assert_equal queryset.count, queryset.length
    assert_equal queryset.empty?, false
    assert_equal queryset.exists?, true
  end

  def test_lookup_contains_count
    assert_equal User.objects.filter(first_name__contains: 'avi').length, 1
    assert_equal User.objects.filter(first_name__startswith: 'Fla').length, 1
    assert_equal User.objects.filter(first_name__endswith: 'vio').length, 1
  end

end