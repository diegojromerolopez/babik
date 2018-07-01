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

#### Selection

Basic selection is made by passing a hash to filter function:

```ruby
User.objects.filter(first_name: 'Flavius', last_name: 'Josephus')
# SELECT users.* FROM users WHERE first_name = 'Flavius' AND last_name = 'Josephus'
```

To make an OR condition, pass an array of hashes:

```ruby
User.objects.filter([{first_name: 'Flavius', last_name: 'Josephus'}, {last_name: 'Iosephus'}])
# SELECT users.*
# FROM users
# WHERE (first_name = 'Flavius' AND last_name = 'Josephus') OR last_name = 'Iosephus'
```

#### Selection by exclusion

You can make negative conditions easily by using **exclude** function:

```ruby
User.objects.exclude(first_name: 'Flavius', last_name: 'Josephus')
# SELECT users.* FROM users WHERE NOT(first_name = 'Flavius' AND last_name = 'Josephus')
```

You can combine **filter** and **exclude** to create complex queries:

```ruby
User.objects.filter([{first_name: 'Marcus'}, {first_name: 'Julius'}]).exclude(last_name: 'Servilia')
# SELECT users.*
# FROM users
# WHERE (first_name = 'Marcus' OR first_name = 'Julius') AND NOT(last_name = 'Servilia')
```

##### Lookups

There are other operators than equal to, these are implemented by using lookups:

###### equal

```ruby
User.objects.filter(first_name: 'Julius')
User.objects.filter(first_name__equal: 'Julius')
# SELECT users.*
# FROM users
# WHERE first_name = 'Julius' 
```

###### exact/iexact

```ruby
User.objects.filter(last_name__exact: nil)
# SELECT users.*
# FROM users
# WHERE last_name IS NULL 
```

```ruby
User.objects.filter(last_name__exact: 'Postumia')
# SELECT users.*
# FROM users
# WHERE last_name LIKE 'Postumia' 
```

###### contains/icontains

```ruby
User.objects.filter(first_name__contains: 'iu')
# SELECT users.*
# FROM users
# WHERE last_name LIKE '%iu%' 
```

###### endswith/iendswith

```ruby
User.objects.filter(first_name__endswith: 'us')
# SELECT users.*
# FROM users
# WHERE last_name LIKE '%us' 
```

###### startswith/istartswith

```ruby
User.objects.filter(first_name__startswith: 'Mark')
# SELECT users.*
# FROM users
# WHERE first_name LIKE 'Mark%' 
```

###### in

```ruby
User.objects.filter(first_name__in: ['Marcus', 'Julius', 'Crasus'])
# SELECT users.*
# FROM users
# WHERE first_name IN ('Marcus', 'Julius', 'Crasus')
```

###### Comparison operators: gt, gte, lt, lte

```ruby
Posts.objects.filter(score__gt: 4)
# SELECT posts.*
# FROM posts
# WHERE score > 4
```

```ruby
Posts.objects.filter(score__lt: 4)
# SELECT posts.*
# FROM posts
# WHERE score < 4
```

```ruby
Posts.objects.filter(score__gte: 4)
# SELECT posts.*
# FROM posts
# WHERE score >= 4
```

```ruby
Posts.objects.filter(score__lte: 4)
# SELECT posts.*
# FROM posts
# WHERE score <= 4
```


###### Other lookups

See more [here](/doc/api/queryset/lookups.md).



#### Selection by foreign model field

The main feature is the filter by foreign keys. This can be done by only 

**NOTE many-to-many relationships are only supported when based on has_many through**

**NO has_and_belongs_to_many support**. [Reason](https://github.com/rubocop-hq/rails-style-guide#has-many-through). 

##### Belongs to relationships

```ruby
User.objects.filter('zone::name': 'Roman Empire')
# SELECT users.*
# FOR users
# LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
# WHERE  users_zone_0 = 'Roman Empire'
```

All depth levels are accepted:

```ruby
User.objects.filter('zone::parent_zone::parent_zone::name': 'Roman Empire')
# SELECT users.*
# FOR users
# LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
# LEFT JOIN geo_zones parent_zones_0 ON users_zone_0.parent_id = parent_zones_0.id
# LEFT JOIN geo_zones parent_zones_1 ON parent_zones_0.parent_id = parent_zones_1.id
# WHERE  parent_zones_1 = 'Roman Empire'
```

##### Has many relationships

```ruby
User.objects.distinct.filter('posts::tag::name': 'history')
# SELECT DISTINCT users.*
# FOR users
# LEFT JOIN posts posts_0 ON users.id = posts_0.author_id
# LEFT JOIN post_tag post_tags_0 ON posts_0.id = post_tags_0.post_id
# LEFT JOIN tags tags_0 ON post_tags_0.tag_id = tags_0.id
# WHERE  post_tag_tags_0 = 'history'
```

Note by using [distinct](/doc/api/queryset/methods/return_queryset.md#distinct)
we have avoided duplicated users (in case the same user has more than one post
with tagged as 'history').

#### Projections

If you are not interested in returned a QuerySet of ActiveRecord objects, it is possible to return
a Result with only the fields you are interested in:

```ruby
p User.objects.filter('zone::name': 'Castilla').order_by('first_name').project('first_name', 'email')
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

## TODO

### Aggregations

[Aggregation functions](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#aggregation-functions)
are not implemented yet.

### Lookups

Django QuerySets have several datetime
lookups that Babik has not implemented:
- [year](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#year)
- [month](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#month)
- [day](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#day)
- [hour](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#hour)
- [minute](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#minute)
- [second](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#second)
- [time](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#time)
- [quarter](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#quarter)
- [week_day](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#week_day)
- [week](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#week)

### Prefect

Nor [Object prefecthing](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#prefetch-objects),
nor [select_realated](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#select-related) are
implemented yet.

### Set operations

- [Difference](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#difference)
- [Intersection](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#intersection)
- [Union](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#union)

## License

[MIT](LICENSE)

## Apendix 1: Example schema


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
    t.integer :stars
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