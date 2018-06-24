# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

class CountTest < Minitest::Test

  def setup
    @parthian_empire = GeoZone.create!(name: 'Parthian Empire')
    @syria = GeoZone.create!(name: 'Syria', parent_zone: @parthian_empire)
    @antioch = GeoZone.create!(name: 'Antioch', parent_zone: @syria)
    @seleucus = User.create!(first_name: 'Seleucus', email: 'seleucus@example.com', zone: @antioch)

    @roman_empire = GeoZone.create!(name: 'Roman Empire')

    @italia = GeoZone.create!(name: 'Italia', parent_zone: @roman_empire)
    @rome = GeoZone.create!(name: 'Rome', parent_zone: @italia)

    @judea = GeoZone.create!(name: 'Judea', parent_zone: @roman_empire)
    @jerusalem = GeoZone.create!(name: 'Jerusalem', parent_zone: @judea)

    @tiberius = User.create!(first_name: 'Tiberius', email: 'tiberius@example.com', zone: @rome)
    @pilate = User.create!(first_name: 'Pontius', last_name: 'Pilate', email: 'pontious@example.com', zone: @jerusalem)
    @flavio = User.create!(first_name: 'Flavio', last_name: 'Josefo', email: 'flaviojosefo@example.com', zone: @jerusalem)
  end

  def teardown
    @parthian_empire.destroy
    @seleucus.destroy
    @roman_empire.destroy
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
    assert_equal active_record_set.count, queryset.count
    assert_equal queryset.length,queryset.count
    assert queryset.empty?
    assert_equal false, queryset.exists?
  end

  # Test the count is well implemented when the returned value is 1
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
    assert_equal active_record_set.count, queryset.count
    assert_equal queryset.length, queryset.count
    assert_equal false, queryset.empty?
    assert_equal true, queryset.exists?
  end

  # Test the count from a deep belongs to relationship
  def test_from_deep_belongs_to
    queryset = User.objects.filter(
      "zone::parent_zone::parent_zone::name__equals": 'Roman Empire'
    )
    assert_equal 3, queryset.count
  end

  # Test the count from a deep belongs to relationship
  def test_or
    queryset = User.objects.filter(
      [
        { "zone::parent_zone::parent_zone::name__equals": 'Roman Empire' },
        { "zone::parent_zone::parent_zone::name__equals": 'Parthian Empire' }
      ]
    )
    number_of_users = 0
    queryset.each do |user|
      assert ['Roman Empire', 'Parthian Empire'].include?(user.zone.parent_zone.parent_zone.name)
      number_of_users += 1
    end
    assert_equal 4, queryset.count
    assert_equal 4, number_of_users
  end

  # Count the objects using contains
  def test_lookup_contains
    assert_equal 1, User.objects.filter(first_name__contains: 'avi').length
    assert_equal 1, User.objects.filter(first_name__startswith: 'Fla').length
    assert_equal 1, User.objects.filter(first_name__endswith: 'vio').length
  end

  def test_lookup_isnull
    assert_equal 0, User.objects.filter('zone::name': 'Rome', email__isnull: true).count
    assert_equal 1, User.objects.filter('zone::name': 'Rome', email__isnull: false).count
    assert_equal 2, User.objects.filter('zone::name': 'Jerusalem', email__isnull: false).count
  end

  def test_date
    today_start = Time.now.beginning_of_day
    today_end = Time.now.end_of_day
    today = Date.today

    number_of_users = User.where('created_at >= ?', today_start).where('created_at <= ?', today_end).count

    assert_equal number_of_users, User.objects.filter(created_at__gte: today_start, created_at__lte: today_end).count
    assert_equal number_of_users, User.objects.filter(created_at__between: [today_start, today_end]).count
    assert_equal number_of_users, User.objects.filter(created_at__date: today).count
  end

end