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
    User.objects.select_related(:zone).each do |user|
      user.objects(:zone)
    end
  end

end