# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of filter method
class FilterTest < Minitest::Test

  def setup
    @asturias = GeoZone.new(name: 'Asturias')
    @cantabria = GeoZone.new(name: 'Cantabria')
    @cangas_de_onis = GeoZone.new(name: 'Cangas de Onís', parent_zone: @asturias)

    User.create!(first_name: 'Pelayo', zone: @cangas_de_onis)
    User.create!(first_name: 'Favila', zone: @cangas_de_onis)
    User.create!(first_name: 'Alfonso I', last_name: 'Católico', zone: @cantabria)
    User.create!(first_name: 'Fruela I', zone: @cangas_de_onis)
  end

  def teardown
    User.delete_all
    GeoZone.delete_all
  end

  def test_local_filter
    kings = User.objects.filter(first_name__endswith: 'I').order_by([:first_name, :ASC])
    asturian_kings = ['Alfonso I', 'Fruela I']
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

  def test_local_or_filter
    kings = User.objects
                .filter([{ first_name: 'Pelayo' }, {'last_name': 'Católico'}])
                .order_by([:first_name, :ASC])
    asturian_kings = ['Alfonso I', 'Pelayo']
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

  def test_foreign_filter
    kings = User.objects
                .filter('zone::parent_zone::name': 'Asturias')
                .order_by([:first_name, :ASC])
    asturian_kings = ['Favila', 'Fruela I', 'Pelayo']
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

  def test_foreign_or_filter
    kings = User.objects
                .filter([{first_name: 'Pelayo'}, {'zone::name': 'Cantabria'}])
                .order_by([:first_name, :ASC])
    asturian_kings = ['Alfonso I', 'Pelayo']
    kings.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

end