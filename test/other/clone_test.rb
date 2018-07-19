# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Class for Tests of dup method
class CloneTest < Minitest::Test

  def setup
    @castille = GeoZone.create!(name: 'Castilla')
    @leon = GeoZone.create!(name: 'León')
    @burgos = GeoZone.create!(name: 'Burgos', parent_zone: @castille)
    @cid = User.create!(first_name: 'Rodrigo', last_name: 'Díaz de Vivar', zone: @burgos)
    @jimena = User.create!(first_name: 'Jimena', last_name: 'Díaz', zone: @burgos)
    @alfonso_vi = User.create!(first_name: 'Alfonso VI', last_name: 'de León', zone: @leon)

    Post.create!(author: @cid, title: 'Cantar del Mío Cid', stars: 4)
    Post.create!(author: @cid, title: 'Mocedades del Cid', stars: 3)
  end

  def teardown
    GeoZone.destroy_all
    User.destroy_all
    Post.destroy_all
  end

  def test_clone
    first_qs = User.objects.filter(first_name: 'whatever').exclude(last_name: 'whatever')
    copy = first_qs.clone

    copy.filter(created_at__lt: Time.now - 1.month)
    first_qs.order_by(id: :DESC)

    assert_equal first_qs._where.model, copy._where.model
    refute_equal first_qs._where.inclusion_filters, copy._where.inclusion_filters
    refute_equal first_qs._where.exclusion_filters, copy._where.exclusion_filters

    assert first_qs.ordered?
    refute copy.ordered?
  end
end
