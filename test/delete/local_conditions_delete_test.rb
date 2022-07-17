# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'
require_relative 'delete_test'

# Tests of delete with local conditions method
class LocalConditionsDeleteTest < DeleteTest
  def test_deletion_from_model
    User.objects.filter(first_name: 'Aulus').delete
    assert_operator 0, :<, User.objects.count
    User.objects.each do |user|
      refute_equal 'Aulus', user.first_name
    end
    assert_equal 0, User.objects.filter(first_name: 'Aulus').count
    assert_equal false, User.objects.filter(first_name: 'Aulus').exists?
  end
end
