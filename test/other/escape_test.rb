# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Check the quotes and strings ar correctly escaped.
class EscapeTest < Minitest::Test
  def setup
    User.create!(first_name: 'Athos')
    User.create!(first_name: 'Porthos')
    User.create!(first_name: 'Aramis')
    User.create!(first_name: "D'Artagnan")
  end

  def test_escape_value
    users = User.objects.filter(first_name: "D'Artagnan")
    assert_equal 1, users.count
  end
end
