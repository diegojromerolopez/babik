# QuerySets

All selections are based on the Django QuerySet and, indeed this API
will have a intended resemblance to the [Django one](https://docs.djangoproject.com/en/2.0/ref/models/querysets/).

A QuerySet is not more than the sum of all conditions that have been applied.
For example, users with first_name equals to 'Pepe' of the zone of 'Madrid'.

## Under the hood

The QuerySet is only really executed when **its elements are accessed**.
Indeed it is based on two methods of ActiveRecord that provides this functionality:

- [ActiveRecord::Base.find_by_sql](http://api.rubyonrails.org/classes/ActiveRecord/Querying.html) for selecting objects (SELECT).
- [ActiveRecord::Base.connection.exec_query](http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/DatabaseStatements.html#method-i-exec_query) for counting objects (SELECT COUNT).
   
Each one of these methods is called by passing directly the generated SQL by the QuerySet.         

## Getting a QuerySet

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

### Loops

To loop through the selected objects, use the same approach
that is used on ActiveRecord:

```ruby
User.objects.filter('zone::name': 'Rome').each do |user_from_rome|
  puts user_from_rome
end
```

## API

- [Methods that return QuerySets](/doc/api/queryset/return_queryset.md). 
  - [Distinct](/doc/api/queryset/return_queryset.md#distinct)
  - [Filter](/doc/api/queryset/return_queryset.md#filter)
  - [Limit](/doc/api/queryset/return_queryset.md#limit)
- [Methods that don't return QuerySets](/doc/api/queryset/dont_return_queryset.md). 
  - [Count](/doc/api/queryset/dont_return_queryset.md#count)
  - [Get](/doc/api/queryset/dont_return_queryset.md#get)
  - [Project](/doc/api/queryset/dont_return_queryset.md#project)


