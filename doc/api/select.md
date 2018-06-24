# Select

Selection is the basic operation of this library.

## QuerySets

All selections are based on the Django QuerySet and, indeed this API
will have a intended resemblance to the [Django one](https://docs.djangoproject.com/en/2.0/ref/models/querysets/).

A QuerySet is not more than the sum of all conditions that have been applied.
For example, users with first_name equals to 'Pepe' of the zone of 'Madrid'.

### Under the hood

The QuerySet is only really executed when **its elements are accessed**.
Indeed it is based on two methods of ActiveRecord that provides this functionality:

- [ActiveRecord::Base.find_by_sql](http://api.rubyonrails.org/classes/ActiveRecord/Querying.html) for selecting objects (SELECT).
- [ActiveRecord::Base.connection.exec_query](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-exec_query) for counting objects (SELECT COUNT).
   
Each one of these methods is called by passing directly the generated SQL by the QuerySet.         

### Getting a QuerySet

When installing this gem, a new method is added to all your ActiveRecord objects:
the **objects** method. This method return a prepared QuerySet.

```ruby
# Return a QuerySet with all users
User.objects.all

# Return a QuerySet with all users whose first name is 'Iacobus' and their zone is 'Rome'
User.objects.filter(first_name: 'Iacobus', 'zone::name': 'Rome')

# Return a QuerySet with all users whose first name is 'Iacobus' or 'Marcus'
User.objects.filter([{first_name: 'Iacobus'}, {first_name: 'Marcus'}])
```

### Filter

Filter is a method that allows to select the desired ActiveRecord objects.

It accepts two kind of parameters:

- A **hash**: then the selection conditions will all be fulfilled.
- An **array of hashes**: then at least one of the selection conditions of one of the item hashes must be fulfilled.

```ruby
# Return a QuerySet with all users whose first name is 'Iacobus' AND last name is 'Paulus'
User.objects.filter(first_name: 'Iacobus', last_name: 'Paulus')

# Return a QuerySet with all users whose first name is 'Iacobus' OR last name is 'Paulus'
User.objects.filter([{first_name: 'Iacobus'}, {last_name: 'Paulus'}])
```

Note the hash contains a simple structure where the key is always a name of a field
as a [symbol](https://ruby-doc.org/core/Symbol.html) and the value will be one
of the accepted values for each filed. Usually, a Ruby String, Number, Date or DateTime.

Thus, note that if a hash is passed as filter argument, its braces
are optional, leaving a more clean code:

```ruby
# Instead of
User.objects.filter({first_name: 'Iacobus', last_name: 'Paulus'})

# We can write
User.objects.filter(first_name: 'Iacobus', last_name: 'Paulus') 
```

#### Local filters

A local filter is one that is composed by fields that belong to the
sender model. i. e. the model class caller.

```ruby
# Return the users created today whose name is 'Tiberius' or 'Pontius'
today = DateTime.today
User.objects
    .filter(created_at__date: today)
    .filter([{first_name: 'Tiberius'}, {first_name: 'Pontius'}])
```

#### Foreign filters

A foreign filter is a filter that makes use of the [associations](http://guides.rubyonrails.org/association_basics.html)
defined on the ActiveRecord model.

Following RuboCop guidelines, [no has_and_belongs_to_many association
will work](https://www.rubydoc.info/gems/rubocop/RuboCop/Cop/Rails/HasAndBelongsToMany),
but only **belongs_to**, **has_one** and **has_many**.

Examples:

```ruby
# Return the users created today whose zone is 'Rome' or 'Utica'
today = DateTime.today
User.objects
    .filter(created_at__date: today)
    .filter([{'zone::name': 'Tiberius'}, {'zone::name': 'Utica'}])
```

```ruby
# Return the users that have posts with the following tags: 'history', 'heraldry', 'battle'
# Note a distinct is included to avoid having repeated users
today = DateTime.today
User.objects
    .distinct
    .filter(created_at__date: today)
    .filter([
      {'posts::tags::name': 'history'},
      {'posts::tags::name': 'heraldry'},
      {'posts::tags::name': 'battle'},
    ])
```

##### Association scopes

At the moment, the implicit conditions defined in the
[association scopes](http://guides.rubyonrails.org/active_record_querying.html#scopes) **are ignored**.

More info about association scopes [here](https://ducktypelabs.com/using-scope-with-associations/).

#### Field lookups

[Field lookups](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#field-lookups) are special operators that can be used to select objects by other conditions
than equality.

For example, comparisons like greater than, less or equal than or between two dates
can be made with lookups. i. e.

```ruby
# Return a QuerySet with all users created today
User.objects.filter(created_at__date: Date.today)
```

See [lookups documentation](/doc/api/lookups.md) for more information. 

### Limit

To limit the amount of results, use the **limit** method.

This method allows two parameters, size and offset.

Note this method will only works with DBMS that support LIMIT statement
(mainly MySQL, PostgreSQL and MariaDB). 

```ruby
# Will return the next 5 users starting from the first one.
User.objects.filter('zone::name': 'Rome').limit(size: 5)

# Will return the next 5 users starting from the sixth one.
User.objects.filter('zone::name': 'Rome').limit(size: 5, offset: 6)
```

### Loops

To loop through the selected objects, use the same approach
that is used on ActiveRecord:

```ruby
User.objects.filter('zone::name': 'Rome').each do |user_from_rome|
  puts user_from_rome
end
```

### Projections

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

### Distinct

Call **distinct** method when we are sure the result of your QuerySet
is going to return repeated columns but you want to ignore them.
For example, in case there is a many-to-many relationship.

```ruby
# If any user has more than one post tagged as 'history'
# it will be returned several times. Applying distinct
# will return only unique users.
User.objects
    .distinct
    .filter('posts::tags::name': 'history')
``` 

### Count

Just call **count** method on the QuerySet to return the number of objects
that match your selection.

More information [here](/doc/api/count.md).