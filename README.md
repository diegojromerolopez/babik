# Babik

A Django [queryset-like](https://docs.djangoproject.com/en/2.0/ref/models/querysets/) API for [Ruby on Rails](https://rubyonrails.org/).

This project is not ready to use in production!

## Install

Add to Gemfile:

```
gem install babik
```

## Usage

See [schema](/README.md#apendix-1:-example-schema) for information about this example's schema.

### Examples


#### Selection operators

```ruby
User.create!(first_name: 'Julius')
User.create!(first_name: 'Octavius')
User.create!(first_name: 'Augustus')
User.create!(first_name: 'Cleopatra')
User.create!(first_name: 'Crassus')
User.create!(first_name: 'Pompey')

User.objects.filter(first_name__equal: 'Julius').count # => 1
User.objects.filter(first_name__different: 'Julius').count # => 5
User.objects.filter(first_name__contains: 'iu').count # => 2
User.objects.filter(first_name__endswith: 'us').count # => 4
User.objects.filter(first_name__startswith: 'C').count # => 2

```

#### Select by foreign model field

```ruby
parthian_empire = GeoZone.create!(name: 'Parthian Empire')
User.create!(first_name: 'Seleucus', zone: parthian_empire)

roman_empire = GeoZone.create!(name: 'Roman Empire')
judea = GeoZone.create!(name: 'Judea', parent_zone: roman_empire)
jerusalem = GeoZone.create!(name: 'Jerusalem', parent_zone: judea )
User.create!(first_name: 'Flavius', last_name: 'Josephux', zone: jerusalem)

loaded_josephus_by_name = User.objects.filter(
  first_name: 'Flavius',
  last_name: 'Josephus'
)

loaded_josephus_by_inmediate_zone = User.objects.filter(
  'zone::name': 'Roman Empire'
).first

loaded_josephus_by_parent_zone = User.objects.filter(
  'zone::parent_zone::name': 'Roman Empire'
).first

loaded_josephus_by_grandparent_zone = User.objects.filter(
  'zone::parent_zone::parent_zone::name': 'Roman Empire'
).first

```

#### Projections

```ruby
castille = GeoZone.create!(name: 'Castilla')
['Juan II', 'Isabel I', 'Juana I'].each do |name|
  User.create!(
    first_name: name,
    last_name: 'de Castilla',
    email: "#{name.downcase.delete(' ')}@example.com",
    zone: castille)
end
```

```ruby
users_projection = User.objects.filter('zone::name': 'Castilla').order_by('first_name').project('first_name', 'email')
# p users_projection
# [
#   { first_name: 'Isabel I', email: 'isabeli@example.com' },
#   { first_name: 'Juan II', email: 'juanii@example.com' },
#   { first_name: 'Juana I', email: 'juanai@example.com' }
# ]
```


## Documentation

See the [documentation](doc/README.md) for more information
about the [API](doc/README.md#API) for information about the API and the
internals of this library.

## License

[MIT](LICENSE)

## Apendix 1: Example schema

Through this documentation this schema will be used, keep it in mind when
reading the examples.

```ruby
ActiveRecord::Schema.define do
  self.verbose = false

  create_table :geo_zones, :force => true do |t|
    t.string :name
    t.text :description
    t.integer :parent_zone_id
    t.timestamps
  end

  create_table :users, :force => true do |t|
    t.integer :zone_id
    t.string :first_name
    t.string :last_name
    t.text :biography
    t.integer :age
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
```