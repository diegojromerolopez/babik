# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of for_update method
class ForUpdateTest < Minitest::Test

  def test_for_update_sql
    assert User.objects.for_update.filter(first_name: 'Marcus').sql.match?('FOR UPDATE')
  end

  def test_lock_sql
    assert User.objects.lock.filter(first_name: 'Marcus').sql.match?('FOR UPDATE')
  end

end