# Methods that don't return QuerySets

## Aggregate

This method will return a hash with the aggregation result.

Valid aggregations are: MAX, MIN, SUM and AVG.

```ruby
caesar = User.objects.get(first_name: 'Julius', last_name: 'Caesar')

# Average number of stars of the posts written by Julius Caesar
caesar.objects.aggregate(avg_stars: Babik.agg(:avg, 'posts::stars')) # {avg_stars: 3.45}

# Other way to do it
caesar.objects(:posts).aggregate(avg_stars: Babik.agg(:avg, 'stars')) # {avg_stars: 3.45}
```

```ruby
# Average number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(avg_stars: Babik.agg(:avg, 'posts::stars')) # {avg_stars: 4.5}

# Min number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(min_stars: Babik.agg(:min, 'posts::stars')) # {min_stars: 1}

# Max number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(min_stars: Babik.agg(:min, 'posts::stars')) # {max_stars: 5}

# Sum of number of stars of users with last name 'Fabia'
User.objects.filter(last_name: 'Favbia').aggregate(sum_of_stars: Babik.agg(:sum, 'posts::stars')) # {sum_of_stars: 5}
```

## All

This method will run the QuerySet and return a query result for your query
(e.g. [PG Result](https://www.rubydoc.info/gems/pg/PG/Result)). 

You don't have to call this method directly unless you want to explicitly
use the query result instead of the QuerySet.

## Brackets

If the brackets operator takes an integer, it will return the ActiveRecord of this QuerySet in that position.

```ruby
# Will return 15 users from the 5th one
User.objects.filter('first_name': 'Romulus').order_by(first_name: :ASC)[5]

# SELECT users.*
# FROM users
# WHERE first_name = 'Romulus'
# ORDER BY first_name ASC
# LIMIT 1 OFFSET 5
```

If there is no ActiveRecord in that position, nill will be returned.

[There is also other way to use to return a section of the QuerySet](/doc/api/queryset/return_queryset.md#brackets).

## Count

Just call **count** method on the QuerySet to return the number of objects
that match your selection.

Call count method to return the number of ActiveRecord objects that match the filter.

### Aliases

- length
- size

### Examples

```ruby
# Number of users with the name Marcus
User.filter(first_name: 'Marcus').count

# Number of users created yesterday
yesterday_limits = [Time.zone.now.beginning_of_day, Time.zone.now.end_of_day]
User.filter(created_at__between: yesterday_limits).count

# Number of users with the surname Smith with an email
User.filter(last_name: 'Smith', email__isnull: false).count

# Number of users created yesterday
User.filter(last_name: 'Smith').count

# Number of users whose geozone is described as a desert.
# That is, contains the desert word (case insensitive).
User.filter(last_name: 'Smith', 'zone::description__icontains': 'desert').count

# Number of users with the surname Smith that have a post tagged with 'history'
User.filter(last_name: 'Smith', 'posts::tags::name': 'history').count
```

## Delete

Delete a bunch of objects by selecting a local or foreign condition.

### Local conditions

```ruby
# Deletes the tags with name 'book'
Tag.objects.filter(name: 'book').delete

# Deletes the users with a gmail email
User.objects.filter(email__endswith: '@gmail.com').delete
```

### Foreign conditions

```ruby
# Deletes the posts tagged as 'war'
Post.objects.filter('tags::name': 'war').delete
```

```ruby
# Deletes the tags of all posts of user called 'Aulus'
Tag.objects.filter('posts::author::first_name': 'Aulus').delete

# Other way to do it by calling delete operation by using an user instance
aulus_user = User.objects.get(first_name: 'Aulus')
aulus_user.objects('posts::tags').filter(name: 'war').delete
```

## Fetch

Returns the elemnt with the index parameter.

If there is no element at that position, if it has a default value, will return it.

If there is no default value, will raise an IndexError exception.

```ruby
# There are only 10 users 'Smith'

# Returns an user (index is in bounds because is less than 10) 
fifth_smith = User.filter(last_name: 'Smith').fetch(5)

# Returns the default value
# (index is not in bounds and a default value is present)
default_value_for_smith = User.filter(last_name: 'Smith').fetch(10_000, 'No user')

# Will raise an IndexError exception
# (index is not in bounds and there is no default value) 
bad_luck_smith = User.filter(last_name: 'Smith').fetch(10_000)
```

## First

Returns the first element of the QuerySet. If the QuerySet is empty, it will return nil.

```ruby
# Return the user with the first name Marcus, whose last name
# is the first one (descending order). 
User.filter(first_name: 'Marcus').order_by([:last_name, :DESC]).first

# Return nil because the first name 'Marcux' is not present in the database
User.filter(first_name: 'Marcux').order_by([:last_name, :DESC]).first
```

## Get

Return the ActiveRecord that matches the condition.

If there is no matching object, will raise a RuntimeError exception 'Does not exist'.
If there is more than one matching object, will raise a RuntimeError exception 'Multiple objects returned'.

```ruby
# Given this initial data
User.create!(first_name: 'Rollo', last_name: 'Lothbrok')
User.create!(first_name: 'Ragnar', last_name: 'Lothbrok')
User.create!(first_name: 'Sigurd', last_name: 'Ring')

# Will raise a 'Does not exist' exception
User.objects.get(last_name: 'Hamundarson') 

# Will raise a 'Multiple objects returned' exception
User.objects.get(last_name: 'Lothbrok')

# Will return a User ActiveRecord
User.objects.get(last_name: 'Ring')
```

## None

Return an empty database-specific query result.

Use when you want to emptying of a QuerySet.

See [all](#all).

## Project

Many times there is no need to get the full object. In that case we
can make use of the projections.

By calling the method **project** of the QuerySet, an
[ActiveRecord Result](http://api.rubyonrails.org/classes/ActiveRecord/Result.html)
will be returned with the projected fields.

Note they can be local and also foreign fields.

Examples:

```ruby
# Return a projection of the first name, email and country of
# all the users with the last name 'García'
User.objects
    .filter('last_name': 'García')
    .order_by('first_name')
    .project('first_name', 'email', %w[zone::name country])
```

