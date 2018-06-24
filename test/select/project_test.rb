# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

class Project < Minitest::Test

  def setup
    @castille = GeoZone.create!(name: 'Castilla')
    ['Juan II', 'Isabel I', 'Juana I'].each do |name|
      User.create!(first_name: name, last_name: 'de Castilla', email: "#{name.downcase.delete(' ')}@example.com", zone: @castille)
    end
    @spain = GeoZone.create!(name: 'España')
    ['Carlos I', 'Felipe II', 'Felipe III'].each do |name|
      User.create!(first_name: name, last_name: 'de Austria', email: "#{name.downcase.delete(' ')}@example.com", zone: @spain)
    end
  end

  def end
    User.delete_all
    GeoZone.delete_all
  end

  def test_project
    users_projection = User.objects.filter('zone::name': 'Castilla').order_by('first_name').project('first_name', 'email')
    users_projection_expectation = [
      { first_name: 'Isabel I', email: 'isabeli@example.com' },
      { first_name: 'Juan II', email: 'juanii@example.com' },
      { first_name: 'Juana I', email: 'juanai@example.com' }
    ]
    users_projection.each_with_index do |user_projection, user_projection_index|
      assert_equal users_projection_expectation[user_projection_index], user_projection.symbolize_keys
    end
  end

  def test_foreign_field_project
    users_projection = User.objects
                           .filter('zone::name': 'Castilla')
                           .order_by('first_name')
                           .project('first_name', 'email', %w[zone::name country])
    users_projection_expectation = [
      { first_name: 'Isabel I', email: 'isabeli@example.com', country: 'Castilla' },
      { first_name: 'Juan II', email: 'juanii@example.com', country: 'Castilla' },
      { first_name: 'Juana I', email: 'juanai@example.com', country: 'Castilla' }
    ]
    users_projection.each_with_index do |user_projection, user_projection_index|
      assert_equal users_projection_expectation[user_projection_index], user_projection.symbolize_keys
    end
  end

end