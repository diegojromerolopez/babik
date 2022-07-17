# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of for_update method
class ForUpdateTest < Minitest::Test
  def test_for_update_sql
    queryset = User.objects.for_update.filter(first_name: 'Marcus')
    assert queryset.sql.select.match?('FOR UPDATE'), queryset.sql.select
  end

  def test_lock_sql
    queryset = User.objects.lock.filter(first_name: 'Marcus')
    assert queryset.sql.select.match?('FOR UPDATE'), queryset.sql.select
  end
end
