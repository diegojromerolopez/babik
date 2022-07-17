# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

class ForeignSelectionTest < Minitest::Test
  def test_equal_in_belongs_to_relationship
    foreign_selection = Babik::Selection::ForeignSelection.new(User, 'zone::name', 'Rome')
    assert_equal foreign_selection.model, User
    assert_equal foreign_selection.associations, [User.reflect_on_association(:zone)]
    assert_equal foreign_selection.selection_path, 'zone::name'
    assert_equal foreign_selection.selected_field, 'name'
    assert_equal foreign_selection.value, 'Rome'
    assert_equal foreign_selection.operator, 'equal'
    assert_equal foreign_selection.sql_where_condition.to_s, 'users__zone_0.name = \'Rome\''
  end

  def test_equal_in_belongs_to_deep_relationship
    foreign_selection = Babik::Selection::ForeignSelection.new(User, 'zone::parent_zone::name', 'Rome')
    assert_equal foreign_selection.model, User

    user_to_zone_association = User.reflect_on_association(:zone)
    _associations_are_equal(foreign_selection.associations[0], user_to_zone_association)

    zone_to_parent_zone_association = GeoZone.reflect_on_association(:parent_zone)
    _associations_are_equal(foreign_selection.associations[1], zone_to_parent_zone_association)

    assert_equal foreign_selection.selection_path, 'zone::parent_zone::name'
    assert_equal foreign_selection.selected_field, 'name'
    assert_equal foreign_selection.value, 'Rome'
    assert_equal foreign_selection.operator, 'equal'
    assert_equal foreign_selection.sql_where_condition.to_s, 'geo_zones__parent_zone_1.name = \'Rome\''
  end

  def test_equal_in_has_many_relationship
    foreign_selection = Babik::Selection::ForeignSelection.new(User, 'posts::tags::name', 'Funny')
    assert_equal foreign_selection.model, User
    assert_equal foreign_selection.selection_path, 'posts::tags::name'
    assert_equal foreign_selection.selected_field, 'name'
    assert_equal foreign_selection.value, 'Funny'
    assert_equal foreign_selection.operator, 'equal'

    assert_equal foreign_selection.sql_where_condition.to_s, 'post_tags__tag_2.name = \'Funny\''
  end

  def _associations_are_equal(association1, association2)
    assert_equal association1.active_record, association2.active_record
    assert_equal association1.name, association2.name
    %w[foreign_key class_name optional].each do |option_key|
      if association1.options[option_key].nil? || association2.options[option_key].nil?
        assert_nil association1.options[option_key]
        assert_nil association2.options[option_key]
      else
        assert_equal association1.options[option_key], association2.options[option_key]
      end
    end
  end
end
