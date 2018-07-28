# Babik

[![Build Status](https://travis-ci.com/diegojromerolopez/babik.svg?branch=master)](https://travis-ci.com/diegojromerolopez/babik)
[![Maintainability](https://api.codeclimate.com/v1/badges/8a64e9a43c77d31a0df1/maintainability)](https://codeclimate.com/github/diegojromerolopez/babik/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/8a64e9a43c77d31a0df1/test_coverage)](https://codeclimate.com/github/diegojromerolopez/babik/test_coverage)

A Django [queryset-like](https://docs.djangoproject.com/en/2.0/ref/models/querysets/) API for [Ruby on Rails](https://rubyonrails.org/).

**This project is in alpha phase. Use it with caution.**

See [Roadmap](#roadmap) to check what is keeping it from being stable.

Contact [me](mailto:diegojromerolopez@gmail.com) if you are interested in
helping me developing it.

## What's this?

This is a library to help you to make queries based on associations without having
to worry about doing joins or writing the exact name of the related table as a prefix
of the foreign field conditions.

### Example: Blog platform in Rails

Suppose you are developing a blog platform with the following [schema](/test/config/db/schema.rb).
Compare these two queries and check what is more easier to write:

Returning all users with last name equals to 'Fabia' that are from Rome:
```ruby
User.joins(:zones).where('last_name': 'Fabia').where('geo_zones.name': 'Rome')
# vs.
User.objects.filter(last_name: 'Fabia', 'zone::name': 'Rome')
```

Returning all users with posts tagged with 'gallic' that are from Rome:
```ruby
User.joins(:zones).joins(posts: :tags)
    .where('last_name': 'Fabia')
    .where('geo_zones.name': 'Rome')
    .where('tags.name': 'gallic')
# vs.
User.objects.filter(
  last_name: 'Fabia',
  'zone::name': 'Rome',
  'posts::tags::name': 'gallic'
)
```

The second alternative is done by using the powerful [Babik querysets](/doc/api/queryset.md).

[See Usage for more examples](#usage).

## Install

Add to Gemfile:

```
gem install babik, git: 'git://github.com/diegojromerolopez/babik.git'
```

No rubygem version for the moment.

## Requirements

Ruby Version >= 2.5

Include all [inverse relationships](http://guides.rubyonrails.org/association_basics.html#bi-directional-associations)
in your models. **It is required to compute the object selection from instance**.

All your many-to-many relationships must have a through attribute.
Per Rubocop guidelines, [using has_and_belongs_to_many is discouraged](https://github.com/rubocop-hq/rails-style-guide#has-many-through).

## Configuration

No configuration is needed, Babik automatically includes two methods for your models:
- **objects** class method to make queries for a model.
- **objects** instance method to make queries from an instance. 

## Database support

PostgreSQL, MySQL and Sqlite are fully supported.

MariaDB and MSSQL should work as well (happy to solve any reported issues).

Accepting contributors to port this library to Oracle.

## Documentation

See the [QuerySet API documentation](/doc/api/queryset.md).

## Main differences with Django QuerySet system
- Django does not make any distinct against relationships, local fields or lookups when selecting by
calling **filter**, **exclude** or **get**. Babik uses **::** for foreign fields.
- Django has a [Q objects](https://docs.djangoproject.com/en/2.0/topics/db/queries/#complex-lookups-with-q-objects)
that allows the construction of complex queries. Babik allows passing an array to selection methods so
there is no need of this artifact.
- Django [select_related](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#select-related)
method cache the objects in the returned object.
We return a pair of objects and a hash with the associated objects. [See doc here](/doc/api/queryset/methods/dont_return_queryset.md#select-related).

## Known issues

### Clone in each non-modifying method call

This library uses [ruby_deep_clone](https://github.com/gmodarelli/ruby-deepclone/) to create a new QuerySet each time
a non-modifying method is called:

```ruby
julius = User.objects.filter(first_name: 'Julius')
julius_caesar = julius.filter(last_name: 'Caesar')

puts julius_caesar == julius
# Will print false
```

This library is somewhat unstable or not as stable as I would like.

## Usage

For a complete reference and full examples of methods, see [documentation](/doc/README.md).

See [schema](/test/config/db/schema.rb) for information about this example's schema.

### objects method

A new **objects** method will be injected in your ActiveRecord classes and instances.

#### Classes

When called from a class, it will return a QuerySet of objects of this class.

```ruby
User.objects.filter(last_name: 'Fabia')
# Returning all users with last name equals to 'Fabia'

User.objects.filter(last_name: 'Fabia', 'zone::name': 'Rome')
# Returning all users with last name equals to 'Fabia' that are from Rome
```

#### Instances

When called from an instance, it will return the foreign related instances:

```ruby
julius = User.objects.get(first_name: 'Julius')
julius.objects('posts').filter(stars__gte: 3)
# Will return the posts written by Julius with 3 or more stars

julius.objects('posts::tags').filter(name__in: ['war', 'battle', 'victory'])
# Will return the tags of posts written by Julius with the names 'war', 'battle' and 'victory'
```
 

### Examples

#### Selection

[See the main docs](/doc/api/queryset/methods/return_queryset.md#filter).

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

#### Selecting one object

```ruby
# Returns an exception if more than one object matches the selection
User.objects.get(id: 258) 

# Returns the first object that matches the selection
User.objects.filter(id: 258).first
```

#### Selecting from an ActiveRecord

You can filter from an actual ActiveRecord object:

```ruby
user = User.objects.get(id: 258)
user.objects('posts::tags').filter(name__in: %w[battle history]).order_by(name: :ASC)
# SELECT users.*
# FROM users
# LEFT JOIN posts posts_0 ON users.id = posts_0.author_id
# LEFT JOIN post_tag post_tags_0 ON posts_0.id = post_tags_0.post_id 
# WHERE post_tags_0.name IN ['battle', 'history']
# ORDER BY post_tags_0.name ASC
```

```ruby
julius = User.objects.get(first_name: 'Julius', last_name: 'Caesar')

# Will return a QuerySet with only the Julius Caesar user (useful for aggregations) 
julius.objects

# Will return a QuerySet with all tags of posts of Julius Caesar
julius.objects('posts::tags') 

# Will return a QuerySet with the GeoZone of Julius Caesar
julius.objects('zone')

```


##### Lookups

[See the main docs](/doc/api/queryset/methods/return_queryset.md#field-lookups).

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

i preceding a comparison operator means case-insensitive version:

```ruby
User.objects.filter(last_name__iexact: 'Postumia')
# SELECT users.*
# FROM users
# WHERE last_name ILIKE 'Postumia' 
```

###### contains/icontains

```ruby
User.objects.filter(first_name__contains: 'iu')
# SELECT users.*
# FROM users
# WHERE last_name LIKE '%iu%' 
```

```ruby
User.objects.filter(first_name__icontains: 'iu')
# SELECT users.*
# FROM users
# WHERE last_name ILIKE '%iu%' 
```

###### endswith/iendswith

```ruby
User.objects.filter(first_name__endswith: 'us')
# SELECT users.*
# FROM users
# WHERE last_name LIKE '%us' 
```

```ruby
User.objects.filter(first_name__iendswith: 'us')
# SELECT users.*
# FROM users
# WHERE last_name ILIKE '%us' 
```

###### startswith/istartswith

```ruby
User.objects.filter(first_name__startswith: 'Mark')
# SELECT users.*
# FROM users
# WHERE first_name LIKE 'Mark%' 
```

```ruby
User.objects.filter(first_name__istartswith: 'Mark')
# SELECT users.*
# FROM users
# WHERE first_name ILIKE 'Mark%' 
```

###### in

```ruby
User.objects.filter(first_name__in: ['Marcus', 'Julius', 'Crasus'])
# SELECT users.*
# FROM users
# WHERE first_name IN ('Marcus', 'Julius', 'Crasus')
```

There is also the possibility to use a subquery instead of a list of elements:

```ruby
Post.objects.filter(id__in: @seneca_sr.objects(:posts).project(:id))
# SELECT posts.*
# FROM posts
# WHERE id IN (SELECT posts.id FROM posts WHERE author_id = 2)
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

The main feature of Babik is filtering by foreign keys. 

Remember:

- **Your associations must have always an inverse (by making use of inverse_of)**. 

- **Many-to-many** relationships are only supported when based on **has_many through**.
[Reason](https://github.com/rubocop-hq/rails-style-guide#has-many-through). 

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

[See the main docs](/doc/api/queryset/methods/dont_return_queryset.md#project).

Return
an [ActiveRecord Result](http://api.rubyonrails.org/classes/ActiveRecord/Result.html)
with only the fields you are interested
by using a [projection](/doc/api/queryset/methods/dont_return_queryset.md#project):

```ruby
p User.objects.filter('zone::name': 'Castilla').order_by('first_name').project('first_name', 'email')

# Query:
# SELECT users.first_name, users.email
# FROM users
# LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
# WHERE users_zone_0.name = 'Castilla'
# ORDER BY users.first_name ASC 

# Result:
# [
#   { first_name: 'Isabel I', email: 'isabeli@example.com' },
#   { first_name: 'Juan II', email: 'juanii@example.com' },
#   { first_name: 'Juana I', email: 'juanai@example.com' }
# ]
```

#### Select related

[See the main docs](/doc/api/queryset/methods/dont_return_queryset.md#select-related).

**select_related** method allows fetching an object and its related ones at once.

```ruby
User.filter(first_name: 'Julius').select_related(:zone)
# Will return in each iteration a list with two elements, the first one
# will be the User instance, and the other one a hash where the keys are
# each one of the association names and the value the associated object 
```

##### Order

[See the main docs](/doc/api/queryset/methods/return_queryset.md#order-by).

Ordering by one field (ASC)

```ruby
User.objects.order_by(:last_name)
# SELECT users.*
# FOR users
# ORDER BY users.last_name ASC 
```

Ordering by one field (DESC)

```ruby
User.objects.order_by(%i[last_name, DESC])
# SELECT users.*
# FOR users
# ORDER BY users.last_name DESC 
```

Ordering by several fields

```ruby
User.objects.order_by(%i[last_name, ASC], %i[first_name, ASC])
# SELECT users.*
# FOR users
# ORDER BY users.last_name ASC, users.first_name ASC
```

Ordering by foreign fields

```ruby
User.objects
    .filter('zone::name': 'Roman Empire')
    .order_by(%i[zone::name, ASC], %i[created_at, DESC])
# SELECT users.*
# FOR users
# LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
# WHERE  users_zone_0 = 'Roman Empire'
# ORDER BY parent_zones_0.name ASC, users.created_at DESC 
```

Inverting the order

```ruby

User.objects
    .filter('zone::name': 'Roman Empire')
    .order_by(%i[zone::name, ASC], %i[created_at, DESC]).reverse
# SELECT users.*
# FOR users
# LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
# WHERE  users_zone_0 = 'Roman Empire'
# ORDER BY parent_zones_0.name DES, users.created_at ASC 
```

#### Delete

[See the main docs](/doc/api/queryset/methods/dont_return_queryset.md#delete).

There is no standard DELETE from foreign field SQL statement, so for now
the default implementation makes use of DELETE WHERE id IN SELECT subqueries.

Future implementations will use joins.

##### Delete by local field

```ruby
User.objects.filter('first_name': 'Julius', 'last_name': 'Caesar').delete
# DELETE
# FROM users
# WHERE id IN ( 
#   SELECT users.*
#   FOR users
#   WHERE users.first_name = 'Julius' AND users.last_name = 'Caesar'
# ) 
```

##### Delete by foreign field

```ruby
GeoZone.get('name': 'Roman Empire').objects('users').delete
User.objects.filter('zone::name': 'Roman Empire').delete
# Both statements are equal:
# DELETE
# FROM users
# WHERE id IN ( 
#   SELECT users.*
#   FOR users
#   LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
#   WHERE  users_zone_0 = 'Roman Empire'
# ) 
```

## Update

[See the main docs](/doc/api/queryset/methods/dont_return_queryset.md#update).

Similar to what happens in when running SQL-delete statements, there is no
standard UPDATE from foreign field SQL statement, so for now
the default implementation makes use of UPDATE SET ... WHERE id IN SELECT subqueries.

Future implementations will use joins.

##### Update by local field

```ruby
User.objects.filter('first_name': 'Julius', 'last_name': 'Caesar').update(first_name: 'Iulius')
# UPDATE SET first_name = 'Iulius'
# FROM users
# WHERE id IN ( 
#   SELECT users.*
#   FOR users
#   WHERE users.first_name = 'Julius' AND users.last_name = 'Caesar'
# ) 
```

##### Update by foreign field

```ruby
GeoZone.get(name: 'Roman Empire').objects('users').filter(last_name__isnull: true).update(last_name: 'Romanum')
User.objects.filter('zone::name': 'Roman Empire', last_name__isnull: true).update(last_name: 'Romanum')
# Both statements are equal:
# UPDATE SET last_name = 'Romanum'
# FROM users
# WHERE id IN ( 
#   SELECT users.*
#   FOR users
#   LEFT JOIN geo_zones users_zone_0 ON users.zone_id = parent_zones_0.id
#   WHERE  users_zone_0 = 'Roman Empire' AND users.last_name IS NULL
# ) 
```

##### Update field by using an actual value of the record

```ruby
Post.objects.filter(stars__gte: 1, stars__lte: 4)
    .update(stars: Babik::QuerySet::Update::Increment.new('stars'))
# UPDATE SET stars = stars + 1
# FROM posts
# WHERE id IN ( 
#   SELECT posts.*
#   FOR posts
#   WHERE  posts.stars >= 1 AND posts.stars <= 4
# ) 
```

## Documentation

See the [documentation](doc/README.md) for more information
about the [API](doc/README.md#queryset-api) and the
internals of this library.



## Unimplemented API

### Methods that return a QuerySet

#### Will be implemented

- [prefetch_related](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#prefetch_related)

##### Set operations

- [Difference](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#difference)
- [Intersection](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#intersection)
- [Union](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#union)

#### Will not be implemented

- [dates](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#dates): [project](/doc/api/queryset/methods/dont_return_queryset.md#project) allow transformer functions that can be used to get dates in the desired format.
- [datetimes](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#datetimes): [project](/doc/api/queryset/methods/dont_return_queryset.md#project) allow transformer functions that can be used to get datetimes in the desired format.
- [extra](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#extra): better use the ActiveRecord API or for raw SQL use [find_by_sql](https://apidock.com/rails/ActiveRecord/Querying/find_by_sql).
- [values](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#values): can be computed using [project](/doc/api/queryset/methods/dont_return_queryset.md#project).
- [values_list](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#values_list):  can be computed using [project](/doc/api/queryset/methods/dont_return_queryset.md#project).
- [raw](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#raw): use ActiveRecord [find_by_sql](https://apidock.com/rails/ActiveRecord/Querying/find_by_sql). Babik is not
for doing raw queries, is for having an additional query system to the ActiveRecord one.
- [using](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#using): to change the database a model
is better to use something like [this](https://stackoverflow.com/questions/180349/how-can-i-dynamically-change-the-active-record-database-for-all-models-in-ruby-o).

#### Under consideration

I am not sure it is a good idea to allow deferred loading or fields. I think is a poor solution for tables with too many
fields. Should I have to take the trouble to implement this two methods?:

- [defer](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#defer)
- [only](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#only)



### Methods that don't return a QuerySet

#### Will not be implemented

The aim of this library is to help make complex queries, not re-implementing the
well-defined and working API of Rails. All of this methods have equivalents in Rails,
but if you are interested, I'm accepting pull-requests. 

- [create](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#create)
- [get_or_create](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#get_or_create)
- [update_or_create](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#update_or_create)
- [bulk_create](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#bulk_create)
- [in_bulk](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#in_bulk)
- [iterator](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#iterator)
- [as_manager](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#as_manager)


### Aggregation functions

#### Will be not implemented

- [expression](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#expression):
there are no [Query Expressions](https://docs.djangoproject.com/en/2.0/ref/models/expressions/)
in Babik, will be possible with the custom aggregations.
- [output_field](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#output_field): already possible passing a hash where the key is the output field. 
- [filter](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#id6): there are no Q objects in Babik.
- [**extra](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#id7): no way to include
extra keyword arguments in the aggregates for now. 


## Roadmap

### Implement remaining methods

As you have seen in the earlier section, there are many methods
that are not implemented yet. This is my aim at short-term.

### Prefect

[Object prefetching](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#prefetch-objects)
is not implemented yet.

### Increase code quality

This project must follow Rubocop directives and pass Reek checks.

### Make a babik-test project

Make a repository with the test schema to check the library is really working.

### Deploy in rubygems

Deploy gem in rubygems.

### Annotations

[Annotations](https://docs.djangoproject.com/en/2.0/topics/db/aggregation/#aggregation)
are not implemented yet.

### Support other DBMS

Oracle is not supported at the moment because of they lack LIMIT clause
in SELECT queries.

## License

[MIT](LICENSE)
