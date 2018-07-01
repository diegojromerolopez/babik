# frozen_string_literal: true

require 'minitest/autorun'
require_relative '../test_helper'

# Tests of aggregate method
class AggregateTest < Minitest::Test

  def setup
    @caesar = User.create!(first_name: 'Julius', last_name: 'Caesar', email: 'backstabbed@example.com')
    [1..7].each do |book_i|
      post = Post.create!(title: "Commentarii de Bello Gallico #{book_i}", author: @caesar)
      post.add_tag(Tag.first_or_create!(name: 'war'))
      post.add_tag(Tag.first_or_create!(name: 'gallic'))
      post.add_tag(Tag.first_or_create!(name: 'tribes'))
      post.add_tag(Tag.first_or_create!(name: 'victory'))
      post.add_tag(Tag.first_or_create!(name: 'campaign'))
    end

    @aulus = User.create!(first_name: 'Aulus', last_name: 'Hirtius', email: 'aulushirtius@example.com')
    last_post = Post.create!(title: 'Commentarii de Bello Gallico 8', author: @aulus)
    last_post.add_tag(Tag.first_or_create!(name: 'war'))
    last_post.add_tag(Tag.first_or_create!(name: 'last_book'))
  end

  def teardown
    Post.destroy_all
    User.destroy_all
  end

  def test_avg
    @caesar.objects(:posts).aggregate(Avg('price'))
  end


end
