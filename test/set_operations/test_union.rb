# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Class for Tests of union method
class UnionTest < Minitest::Test

  def setup

    patrician_families = %w[
      Aebutia Aemilia Aquillia Atilia Claudia Cloelia Cornelia Curtia
      Fabia Foslia Furia Gegania Genucia Herminia Horatia Julia Lartia
      Lucretia Manlia Menenia Metilia Minucia Mucia Nautia Numicia Papiria
      Pinaria Pollia Postumia Potitia Quinctia Quinctilia Romilia
      Sempronia Sergia Servilia Sestia Siccia Sulpicia Tarpeia Tarquinia
      Tarquitia Tullia Valeria Verginia Veturia Vitellia Volumnia
    ]
    roman_names = %w[
      Aeliana Albia Antonia Aquilia Argentia Atticus Augusta Augustus Aurelia Aurelius Avita Caesar Camilla
      Cassia Cassius Cato Cecilia Cicero Claudia Claudius Clemensia Cornelius Crispus Cyprian Decima Decimus
      Drusilla Dulcia Fabia Faustina Felix Flavia Florentina Fortunata Gaia Galla Hilaria Horatia Julia Julius
      Junia Justus Laelia Laurentia Livia Lucius Lucretia Magnus Marcella Marcus Marilla Marius Martia Maxima
      Maximus Mila Nerilla Nero Octavia Octavius Philo Prima Priscilla Quintia Quintus Remus Romulus Rufina
      Rufus Sabina Seneca Septima Septimus Sergia Tanaquil Tatiana Tauria Tertia Tiberius Tullia Urban Urbana
      Valentina Varinia Vita
    ]

    random_generator = Random.new(1234)
    patrician_families.each do |family_name|
      roman_names.each do |roman_name|
        User.create!(first_name: roman_name, last_name: family_name) if random_generator.rand(0..1) == 1
      end
    end

  end

  def teardown
    User.destroy_all
  end

  def _test_union
    claudia = User.objects.filter(last_name: 'Claudia')
    verturia = User.objects.filter(last_name: 'Veturia')
    both_families = claudia.union(verturia).order_by(last_name: :DESC)
    both_families_without_union = User.where(last_name: ['Claudia', 'Veturia']).order(last_name: :DESC)
    assert_equal both_families_without_union.count, both_families.count
  end

end