# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Class for basic set operation tests
class BasicUsageTest < Minitest::Test

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

  def test_union
    claudia = User.objects.filter(last_name: 'Claudia')
    verturia = User.objects.filter(last_name: 'Veturia')
    both_families = claudia.union(verturia).order_by!({ last_name: :DESC }, { first_name: :ASC })
    both_families_without_union = User.where(last_name: ['Claudia', 'Veturia']).order(last_name: :DESC, first_name: :ASC)
    _check_set_operation(both_families_without_union, both_families)
  end

  def test_deep_union
    claudia = User.objects.filter(last_name: 'Claudia')
    verturia = User.objects.filter(last_name: 'Veturia')
    aemilia = User.objects.filter(last_name: 'Aemilia')
    three_families = claudia.union(verturia).union(aemilia).order_by!({ last_name: :DESC }, { first_name: :ASC })
    three_families_without_union = User
                                   .where(last_name: ['Claudia', 'Veturia', 'Aemilia'])
                                   .order(last_name: :DESC, first_name: :ASC)
    _check_set_operation(three_families_without_union, three_families)
  end

  def test_intersection
    first_user = User.objects.first
    qs_with_intersection = User.objects.filter(first_name: first_user.first_name)
                               .intersection(User.objects.filter(last_name: first_user.last_name))
                               .order_by!({ last_name: :DESC }, { first_name: :ASC })
    qs_without_intersection = User.where(first_name: first_user.first_name, last_name: first_user.last_name)
                                      .order(last_name: :DESC, first_name: :ASC)
    _check_set_operation(qs_without_intersection, qs_with_intersection)
  end

  def test_deep_intersection
    first_user = User.objects.first
    qs_with_intersection = User.objects.filter(first_name: first_user.first_name)
                               .intersection(User.objects.filter(last_name: first_user.last_name))
                               .intersection(User.objects.filter(created_at__lt: Time.now))
                               .order_by!({ last_name: :DESC }, { first_name: :ASC })
    qs_without_intersection = User.where(first_name: first_user.first_name, last_name: first_user.last_name)
                                .order(last_name: :DESC, first_name: :ASC)
    _check_set_operation(qs_without_intersection, qs_with_intersection)
  end

  def test_difference
    first_user = User.objects.first
    qs_with_minus = User.objects
                        .filter(last_name: first_user.last_name)
                        .difference(User.objects.filter(first_name: first_user.first_name))
                        .order_by!({ last_name: :DESC }, { first_name: :ASC })
    qs_without_minus = User.where(last_name: first_user.last_name)
                           .where.not(first_name: first_user.first_name)
                           .order(last_name: :DESC, first_name: :ASC)
    _check_set_operation(qs_without_minus, qs_with_minus)
  end

  # Check a set-operation based queryset is correct
  def _check_set_operation(expected_qs, actual_qs)
    record_count = 0
    expected_qs.each_with_index do |expected_qs_record, expected_qs_record_index|
      actual_qs_record = actual_qs[expected_qs_record_index]
      assert_equal expected_qs_record.id, actual_qs_record.id
      assert_equal expected_qs_record.last_name, actual_qs_record.last_name
      assert_equal expected_qs_record.first_name, actual_qs_record.first_name
      assert_equal expected_qs_record.last_name, actual_qs_record.last_name
      record_count += 1
    end
    assert_equal expected_qs.count, actual_qs.count
    assert_equal expected_qs.count, record_count
  end

end