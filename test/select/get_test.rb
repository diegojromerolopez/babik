# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

class GetTest < Minitest::Test

  def setup
    User.create!(first_name: 'Rollo', last_name: 'Lothbrok')
    User.create!(first_name: 'Ragnar', last_name: 'Lothbrok')
    User.create!(first_name: 'Sigurd', last_name: 'Ring')
    User.create!(first_name: 'Freydis', last_name: 'Eriksdottir')
    User.create!(first_name: 'Harald', last_name: 'Hardrada')
  end

  def teardown
    User.delete_all
  end

  def test_get_ok
    freydis = User.objects.get(last_name: 'Eriksdottir')
    assert_equal 'Freydis', freydis.first_name
    assert_equal 'Eriksdottir', freydis.last_name
  end

  def test_get_not_found
    exception = assert_raises RuntimeError do
      User.objects.get(last_name: 'Last name that does not exist')
    end
    assert_equal('Does not exist', exception.message)
  end

  def test_get_not_several_objects_returned
    exception = assert_raises RuntimeError do
      User.objects.get(last_name: 'Lothbrok')
    end
    assert_equal('Multiple objects returned', exception.message)
  end
end