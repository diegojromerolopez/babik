# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Class for Tests of clone method
class CloneTest < Minitest::Test

  def test_filter
    filter = { first_name: 'whatever1' }
    exclusion = { last_name: 'whatever1' }

    original = User.objects.filter(filter).exclude(exclusion)
    copy = original.clone

    refute_equal original.object_id, copy.object_id

    assert_equal original._where.model, copy._where.model

    refute_equal original._where.inclusion_filters.object_id, copy._where.inclusion_filters.object_id
    refute_equal original._where.inclusion_filters[0].object_id, copy._where.inclusion_filters[0].object_id

    refute_equal original._where.exclusion_filters.object_id, copy._where.exclusion_filters.object_id
    refute_equal original._where.exclusion_filters[0].object_id, copy._where.exclusion_filters[0].object_id
  end

  def test_or_filter
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    exclusion = [{ last_name: 'whatever1' }, { last_name: 'whatever2' }]

    original = User.objects.filter(filter).exclude(exclusion)
    copy = original.clone

    refute_equal original.object_id, copy.object_id

    assert_equal original._where.model, copy._where.model

    refute_equal original._where.inclusion_filters.object_id, copy._where.inclusion_filters.object_id
    refute_equal original._where.inclusion_filters[0].object_id, copy._where.inclusion_filters[0].object_id

    refute_equal original._where.exclusion_filters.object_id, copy._where.exclusion_filters.object_id
    refute_equal original._where.exclusion_filters[0].object_id, copy._where.exclusion_filters[0].object_id
  end

  def test_distinct
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    exclusion = [{ last_name: 'whatever1' }, { last_name: 'whatever2' }]

    original = User.objects.filter(filter).exclude(exclusion)
    copy = original.distinct
    copy_undistinct = original.undistinct

    refute_equal original.object_id, copy.object_id
    refute_equal original.object_id, copy_undistinct.object_id
    refute original.distinct?
    assert copy.distinct?
    refute copy_undistinct.distinct?
  end

  def test_limit
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    original = User.objects.filter(filter)
    copy1 = original.limit(2, 10)
    copy2 = original[2..10]
    refute_equal original.object_id, copy1.object_id
    refute_equal original.object_id, copy2.object_id
    refute_equal copy1.object_id, copy2.object_id
  end

  def test_lockable
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    original = User.objects.filter(filter)
    copy1 = original.lock
    copy2 = original.for_update
    refute_equal original.object_id, copy1.object_id
    refute_equal original.object_id, copy2.object_id
    refute_equal copy1.object_id, copy2.object_id
  end

  def test_projectable
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    original = User.objects.filter(filter)
    copy1 = original.project(:id, :first_name)
    copy2 = original.project(:id, :first_name, :last_name)
    copy3 = copy2.unproject
    refute_equal original.object_id, copy1.object_id
    refute_equal original.object_id, copy2.object_id
    refute_equal original.object_id, copy3.object_id
    refute_equal copy1.object_id, copy2.object_id
    refute_equal copy1.object_id, copy3.object_id
    refute_equal copy2.object_id, copy3.object_id
  end

  def test_sortable
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    original = User.objects.filter(filter)
    copy1 = original.order_by(first_name: :ASC)
    copy2 = original.order(id: :ASC)
    copy3 = copy2.order(%i[last_name DESC])
    refute_equal original.object_id, copy1.object_id
    refute_equal original.object_id, copy2.object_id
    refute_equal original.object_id, copy3.object_id
    refute_equal copy1.object_id, copy2.object_id
    refute_equal copy1.object_id, copy3.object_id
    refute_equal copy2.object_id, copy3.object_id
  end

  def test_deletable
    filter = [{ first_name: 'Julius' }, { first_name: 'Marcus' }]
    names = %w[Julius Marcus Tiberius Pontius Crassus]
    names.each do |name|
      User.create(first_name: name)
    end
    users = User.objects.filter(filter)
    users.delete

    assert_equal 0, users.count
    assert_equal 3, User.objects.count

    User.destroy_all
  end

  def test_clone
    filter = [{ first_name: 'whatever1' }, { first_name: 'whatever2' }]
    original = User.objects.filter(filter)
    original.clone.clone
  end

end
