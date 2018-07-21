# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Limit method tests
class LimitTest < Minitest::Test

  def setup
    i = 0
    while i < 100
      User.create!(first_name: "User #{i + 1}", last_name: 'LimitTest user')
      i += 1
    end
  end

  def teardown
    User.delete_all
  end

  def test_limit
    page_size = 5

    # Check the first page of users
    first_page = User.objects.filter(last_name: 'LimitTest user').limit(page_size)
    # Check with each
    loops = 0
    first_page.each do |user|
      assert_equal "User #{loops + 1}", user.first_name
      loops += 1
    end
    assert_equal page_size, loops

    # Check the second page of users
    second_page_offset = page_size
    second_page = User.objects.filter(last_name: 'LimitTest user').limit(page_size, second_page_offset)
    assert_equal 5, second_page.count
    second_page.each_with_index do |user, user_index|
      assert_equal "User #{user_index + second_page_offset + 1}", user.first_name
    end
  end

  def test_limit_brackets
    page_size = 5
    first_page = User.objects.filter(last_name: 'LimitTest user').limit(page_size)
    first_page_with_brackets = User.objects.filter(last_name: 'LimitTest user')[0..page_size]
    limit_test_user = User.objects.filter(last_name: 'LimitTest user')[page_size]
    assert_equal 'No user', User.objects.filter(last_name: 'LimitTest user').fetch(10_000, 'No user')

    non_existent_index = User.objects.count + 100
    exception = assert_raises IndexError do
      User.objects.filter(last_name: 'LimitTest user').fetch(non_existent_index)
    end
    limit_test_count = User.objects.filter(last_name: 'LimitTest user').count

    assert_equal("Index #{non_existent_index} outside of QuerySet bounds", exception.message)
    assert_equal User, limit_test_user.class
    assert_equal 'LimitTest user', limit_test_user.last_name
    assert_equal first_page.count, first_page_with_brackets.count

    second_page_offset = page_size
    second_page = User.objects.filter(last_name: 'LimitTest user').limit(page_size, second_page_offset)
    second_page_with_brackets = User.objects.filter(last_name: 'LimitTest user')[second_page_offset..(second_page_offset+page_size)]
    assert_equal page_size, second_page.count
    assert_equal second_page.count, second_page_with_brackets.count
  end

  def test_limit_brackets_index
    first_user = User.objects.filter(last_name: 'LimitTest user').order_by(created_at: :ASC)[0]
    assert_equal 'User 1', first_user.first_name
  end

  def test_brackets_index_out_of_range
    assert_nil User.objects.filter(last_name: 'LimitTest user').order_by(created_at: :ASC)[1000]
  end

  def test_brackets_invalid_value
    exception = assert_raises RuntimeError do
      assert_raises User.objects.filter(last_name: 'LimitTest user').order_by(created_at: :ASC)['INVALID VALUE']
    end
    assert_equal('Invalid limit passed to query: INVALID VALUE', exception.message)
  end

  def test_fetch_index_out_of_range
    exception = assert_raises IndexError do
      assert_raises User.objects.filter(last_name: 'LimitTest user').order_by(created_at: :ASC).fetch(1000)
    end
    assert_equal('Index 1000 outside of QuerySet bounds', exception.message)
  end

end