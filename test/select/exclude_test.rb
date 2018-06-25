# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of exclude method
class ExcludeTest < Minitest::Test

  def setup
    @asturias = GeoZone.new(name: 'Asturias')
    @cantabria = GeoZone.new(name: 'Cantabria')
    @cangas_de_onis = GeoZone.new(name: 'Cangas de Onís', parent_zone: @asturias)
    @oviedo = GeoZone.new(name: 'Oviedo', parent_zone: @asturias)

    User.create!(first_name: 'Pelayo', biography: 'Unknown origin', zone: @cangas_de_onis)
    User.create!(first_name: 'Favila', biography: 'Short reign of two years, seven months and ten days', zone: @cangas_de_onis)
    User.create!(first_name: 'Alfonso I', last_name: 'El Católico', biography: 'Son-in-law of Don Pelayo', zone: @cantabria)
    User.create!(first_name: 'Fruela I', last_name: 'Hombre de Hierro', biography: 'Killed by conspirators', zone: @cangas_de_onis)
    User.create!(first_name: 'Aurelio', biography: 'Chosen by Asturian nobility', zone: @asturias)
    User.create!(first_name: 'Silo', biography: 'Peace period', zone: @asturias)
    User.create!(first_name: 'Alfonso II', last_name: 'El Casto', biography: 'Discovered Saint James tomb', zone: @oviedo)
    User.create!(first_name: 'Mauregato', biography: 'Paid the 100 maidens tribute to Cordova Emirate', zone: @asturias)
    User.create!(first_name: 'Bermudo I', last_name: 'El Diácono', biography: 'Cultured, magnanimous and illustrated man')
    User.create!(first_name: 'Nepociano', last_name: 'El usurpador')
    User.create!(first_name: 'Ramiro I', last_name: 'Vara de la Justicia', zone: @oviedo)
    User.create!(first_name: 'Ordoño I', biography: 'Failed first attemp to reconquer the kingdom', zone: @oviedo)
    User.create!(first_name: 'Alfonso III', last_name: 'El Magno', biography: 'Last king of Independent Asturian kingdom')
    User.create!(first_name: 'Fruela II', last_name: 'El leproso', biography: 'Last king of Asturian kingdom')
  end

  def teardown
    User.delete_all
  end

  def test_local_exclude
    kings_with_bio_out_without_ordinal = User.objects
                                             .filter(biography__isnull: false)
                                             .exclude(first_name__endswith: 'I')
                                             .order_by([:first_name, :ASC])
    asturian_kings = ['Aurelio', 'Favila', 'Mauregato', 'Pelayo', 'Silo']
    kings_with_bio_out_without_ordinal.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

  def test_foreign_exclude
    kings_with_bio_not_from_oviedo = User.objects
                                         .filter(biography__isnull: false)
                                         .exclude('zone::name': 'Oviedo')
                                         .order_by([:first_name, :ASC])
    asturian_kings = ['Alfonso I', 'Aurelio', 'Favila', 'Fruela I', 'Mauregato', 'Pelayo', 'Silo']
    kings_with_bio_not_from_oviedo.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

  def test_foreign_complex_exclude
    kings_not_from_oviedo_not_named_alfonso = User.objects
                                                  .exclude(
                                                    [
                                                      { 'zone::name': 'Oviedo' },
                                                      { first_name__startswith: 'Alfonso' }
                                                    ]
                                                  )
                                                  .order_by([:first_name, :ASC])
    asturian_kings = ['Aurelio', 'Favila', 'Fruela I', 'Mauregato', 'Pelayo', 'Silo']
    kings_not_from_oviedo_not_named_alfonso.each_with_index do |king, king_i|
      assert_equal asturian_kings[king_i], king.first_name
    end
  end

end
