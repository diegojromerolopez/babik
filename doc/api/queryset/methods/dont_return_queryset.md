# Methods that don't return QuerySets

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

## First

Return the first element of the QuerySet. If the QuerySet is empty, it will return nil.

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