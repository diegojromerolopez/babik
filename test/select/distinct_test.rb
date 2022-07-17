# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of distinct method
class DistinctTest < Minitest::Test
  def setup
    User.create!(first_name: 'Diego', last_name: 'de Siloé')
    User.create!(first_name: 'Diego', last_name: 'Velazquez')
  end

  def teardown
    User.delete_all
  end

  def test_local_distinct
    assert_equal 2, User.objects.filter(first_name: 'Diego').project(:first_name).count
    assert_equal 1, User.objects.distinct.filter(first_name: 'Diego').project(:first_name).count
    assert User.objects.distinct.filter(first_name: 'Diego').distinct?
  end

  def test_local_distinct_from_queryset
    diegos = User.objects.filter(first_name: 'Diego').project(:first_name).distinct
    assert diegos.distinct?
    refute diegos.undistinct.distinct?
    assert_equal 1, diegos.count
  end

  def test_local_undistinct
    diegos = User.objects.filter(first_name: 'Diego').project(:first_name)
    refute diegos.distinct?
    assert_equal 2, diegos.count
    assert_equal diegos.count, diegos.distinct.undistinct.count
  end
end
