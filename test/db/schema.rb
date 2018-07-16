ActiveRecord::Schema.define do
  self.verbose = false

  create_table :geo_zones, force: true do |t|
    t.string :name
    t.text :description
    t.integer :parent_zone_id
    t.timestamps
  end

  create_table :group, force: true do |t|
    t.string :name
    t.string :description
    t.timestamps
  end

  create_table :group_users, force: true do |t|
    t.integer :group_id
    t.integer :user_id
    t.timestamps
  end

  create_table :users, force: true do |t|
    t.integer :zone_id
    t.string :first_name
    t.string :last_name
    t.text :biography
    t.integer :age
    t.string :email
    t.timestamps
  end

  create_table :posts, force: true do |t|
    t.string :title
    t.text :content
    t.integer :stars
    t.integer :author_id
    t.integer :category_id
    t.timestamps
  end

  create_table :post_tags, force: true do |t|
    t.integer :post_id
    t.integer :tag_id
    t.timestamps
  end

  create_table :tags, force: true do |t|
    t.string :name
    t.timestamps
  end

  create_table :categories, force: true do |t|
    t.string :name
    t.timestamps
  end

  # Tag class that will make use of a has_and_belongs_to_many relationship
  # Used only for test the detection of has_and_belongs_to_many and the raise
  # of an exception happens
  create_table :bad_tags, force: true do |t|
    t.string :name
    t.timestamps
  end

  add_index :users, :email, unique: true
  add_index :group_users, [:group_id, :user_id], unique: true
  add_index :categories, :name, unique: true
  add_index :post_tags, [:post_id, :tag_id], unique: true
  add_index :posts, [:title, :author_id], unique: true
end