# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

class LocalSelectionTest < Minitest::Test
  def test_equal_selection
    local_selection = Babik::Selection::LocalSelection.new(User, 'first_name', 'Pepe')
    assert_equal local_selection.model, User
    assert_equal local_selection.selection_path, 'first_name'
    assert_equal local_selection.selected_field, 'first_name'
    assert_equal local_selection.value, 'Pepe'
    assert_equal local_selection.operator, 'equal'
  end

  def test_selection_icontains
    local_selection = Babik::Selection::LocalSelection.new(User, 'firstname__icontains', 'Pepe')
    assert_equal local_selection.model, User
    assert_equal local_selection.selection_path, 'firstname__icontains'
    assert_equal local_selection.selected_field, 'firstname'
    assert_equal local_selection.value, 'Pepe'
    assert_equal local_selection.operator, 'icontains'
  end
end
