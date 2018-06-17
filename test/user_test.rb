# frozen_string_literal: true

require 'minitest/autorun'
require_relative 'test_helper'

class UserTest < Minitest::Test

  def setup
    @geozone = GeoZone.create!(name: "Rome")
    @flavio = User.create!(first_name: "Flavio", last_name: "Josefo", email: "flaviojosefo@example.com", zone: @geozone)
    Post.create!(title: "Flavio is happy", content: "Flavio is happy in Palestine", author: @flavio)
  end

  def test_lookup_equal
    #queryset = User.objects.filter({tag__first_name: "Flavio", last_name: "Josefo"})
    #queryset = User.objects.filter({"zone__name": "Rome"})
    #queryset = Post.objects.filter({"author::zone__name": "Rome"})
    queryset = User.objects.filter(
        {
                first_name: "Flavio",
                last_name: "Josefo",
                "zone::name__different": "Rome",
                "zone::description": "Madrid"
               }
    )
    puts queryset.sql
    #assert_equal User.objects.filter(first_name: "Flavio", last_name: "Josefo").length, 1
    #assert_equal User.objects.get(first_name: "Flavio").id, @flavio.id
  end

  def _test_lookup_contains
    assert_equal User.objects.filter(name__contains="vio").length, 1
    assert_equal User.objects.filter(name__contains="vio").count, 1
    assert_equal User.objects.filter(name__contains="vio").count, 1
  end

end