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
  end

  def teardown
    GeoZone.destroy_all
    User.destroy_all
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

end