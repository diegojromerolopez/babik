# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Abstract class for Tests of delete method
class DeleteTest < Minitest::Test

  def setup
    war_tag = Tag.create!(name: 'war')
    tribes_tag = Tag.create!(name: 'tribes')
    gallic_tag = Tag.create!(name: 'gallic')
    victory_tag = Tag.create!(name: 'victory')
    campaign_tag = Tag.create!(name: 'campaign')
    book_tag = Tag.create!(name: 'book')
    last_book_tag = Tag.create!(name: 'last_book')

    @caesar = User.create!(first_name: 'Julius', last_name: 'Caesar', email: 'backstabbed@example.com')
    (1..7).each do |book_i|
      post = Post.create!(title: "Commentarii de Bello Gallico #{book_i}", author: @caesar, stars: [book_i, 5].min)
      post.add_tag(war_tag)
      post.add_tag(gallic_tag)
      post.add_tag(tribes_tag)
      post.add_tag(victory_tag)
      post.add_tag(book_tag)
      post.add_tag(campaign_tag)
    end

    @aulus = User.create!(first_name: 'Aulus', last_name: 'Hirtius', email: 'aulushirtius@example.com')
    last_post = Post.create!(title: 'Commentarii de Bello Gallico 8', author: @aulus)
    last_post.add_tag(war_tag)
    last_post.add_tag(book_tag)
    last_post.add_tag(last_book_tag)
  end

  def teardown
    Tag.destroy_all
    Post.destroy_all
    User.destroy_all
  end

  def delete_by_local_selection
    User.objects.filter(first_name: 'Julius').delete
    assert_nil User.objects.filter(first_name: 'Julius').first
    assert_equal 1, User.objects.count
  end

  def test_delete_by_foreign_selection
    Post.objects.filter('author::first_name': 'Julius', title: 'Commentarii de Bello Gallico 2').delete
    assert_nil Post.objects.filter('author::first_name': 'Julius', title: 'Commentarii de Bello Gallico 2').first
    assert_equal 6, @caesar.objects(:posts).count
  end

  def test_delete_by_instance_foreign_selection
    @caesar.objects(:posts).filter(title: 'Commentarii de Bello Gallico 2').delete
    assert_nil @caesar.objects(:posts).filter(title: 'Commentarii de Bello Gallico 2').first
    assert_equal 6, @caesar.objects(:posts).count
  end

end
