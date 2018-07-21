# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Project method test
class ProjectTest < Minitest::Test

  def setup
    if GeoZone.objects.filter(name: 'Castilla').exists?
      return
    end
    @castille = GeoZone.create!(name: 'Castilla')
    ['Juan II', 'Isabel I', 'Juana I'].each do |name|
      User.create!(first_name: name, last_name: 'de Castilla', email: "#{name.downcase.delete(' ')}@example.com", zone: @castille)
    end
    @spain = GeoZone.create!(name: 'España')
    ['Carlos I', 'Felipe II', 'Felipe III'].each do |name|
      User.create!(first_name: name, last_name: 'de Austria', email: "#{name.downcase.delete(' ')}@example.com", zone: @spain)
    end
  end

  def teardown
    User.destroy_all
    GeoZone.destroy_all
  end

  def test_project
    users_projection = User.objects
                           .filter('zone::name': 'Castilla')
                           .order_by('first_name')
                           .project('first_name', 'email')

    local_projection_expectation = [
      { first_name: 'Isabel I', email: 'isabeli@example.com' },
      { first_name: 'Juan II', email: 'juanii@example.com' },
      { first_name: 'Juana I', email: 'juanai@example.com' }
    ]

    assert users_projection.projection?
    users_projection.each_with_index do |user_projection, user_projection_index|
      assert_equal local_projection_expectation[user_projection_index], user_projection.symbolize_keys
    end
  end

  def test_no_projection
    users_projection = User.objects
                           .filter('zone::name': 'Castilla')
                           .order_by('first_name')
    refute users_projection.projection?
  end

  def test_foreign_field_project
    users_projection = User.objects
                           .filter('zone::name': 'Castilla')
                           .order_by('first_name')
                           .project('first_name', 'email', %w[zone::name country])
    foreign_projection_expectation = [
      { first_name: 'Isabel I', email: 'isabeli@example.com', country: 'Castilla' },
      { first_name: 'Juan II', email: 'juanii@example.com', country: 'Castilla' },
      { first_name: 'Juana I', email: 'juanai@example.com', country: 'Castilla' }
    ]

    assert users_projection.projection?
    users_projection.each_with_index do |user_projection, user_projection_index|
      assert_equal foreign_projection_expectation[user_projection_index], user_projection.symbolize_keys
    end
  end

end