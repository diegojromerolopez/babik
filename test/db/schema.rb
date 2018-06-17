ActiveRecord::Schema.define do
  self.verbose = false

  create_table :geo_zones, :force => true do |t|
    t.string :name
    t.text :description
    t.timestamps
  end

  create_table :users, :force => true do |t|
    t.integer :zone_id
    t.string :first_name
    t.string :last_name
    t.string :email
    t.timestamps
  end

  create_table :posts, :force => true do |t|
    t.string :title
    t.text :content
    t.integer :author_id
    t.timestamps
  end

  create_table :post_tags, :force => true do |t|
    t.integer :post_id
    t.integer :tag_id
    t.timestamps
  end

  create_table :tags, :force => true do |t|
    t.string :name
    t.timestamps
  end

end