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

- [Methods that return a QuerySet](/doc/api/queryset/methods/return_queryset.md). 
  - [\[\] operator](/doc/api/queryset/methods/return_queryset.md#brackets): returns an slice of the QuerySet.
  - [Distinct](/doc/api/queryset/methods/return_queryset.md#distinct): make the query to return unique rows.
  - [Exclude](/doc/api/queryset/methods/return_queryset.md#exclude): add more excluding conditions to the query.
  - [Filter](/doc/api/queryset/methods/return_queryset.md#filter): add more including conditions to the query.
  - [Limit](/doc/api/queryset/methods/return_queryset.md#limit): returns an slice of the QuerySet.
- [Methods that don't return a QuerySet](/doc/api/queryset/methods/dont_return_queryset.md). 
  - [aggregate](/doc/api/queryset/methods/dont_return_queryset.md#aggregate): returns a hash with the result of one valid aggregation (AVG, MIN, MAX, SUM).
  - [All](/doc/api/queryset/methods/dont_return_queryset.md#all): returns the query result corresponding to your query.
  - [\[\] operator](/doc/api/queryset/methods/dont_return_queryset.md#brackets): returns an ActiveRecord object or nil.
  - [Delete](/doc/api/queryset/methods/dont_return_queryset.md#delete): returns nothing.
  - [Count](/doc/api/queryset/methods/dont_return_queryset.md#count): returns a positive or zero integer.
  - [Fetch](/doc/api/queryset/methods/dont_return_queryset.md#fetch): returns an ActiveRecord object or default value.
  - [First](/doc/api/queryset/methods/dont_return_queryset.md#first): returns an ActiveRecord object or nil.
  - [Get](/doc/api/queryset/methods/dont_return_queryset.md#get): returns an ActiveRecord object.
  - [None](/doc/api/queryset/methods/dont_return_queryset.md#none): returns an empty query result.
  - [Project](/doc/api/queryset/methods/dont_return_queryset.md#project): returns a [Result](http://api.rubyonrails.org/classes/ActiveRecord/Result.html).
  - [Select related](/doc/api/queryset/methods/dont_return_queryset.md#select-related): returns a pair of ActiveRecord::Base object, Hash with the related objects.
  - [Update](/doc/api/queryset/methods/dont_return_queryset.md#update): update the records that match the condition. Returns empty array.


