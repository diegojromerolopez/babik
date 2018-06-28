# Lookups

Field lookups are operators that can be used in filters to select the desired
objects.

Field lookups in Babik are [based on Django QuerySet ones](https://docs.djangoproject.com/en/2.0/ref/models/querysets/#field-lookups).

## exact

Compares the exact same value but in the case the values is null, the comparison
will be generated with **IS NULL**.

```ruby
User.objects.filter('email__exact': nil)
# SELECT users.* FROM users WHERE email IS NULL

User.objects.filter('email__exact': 'peters@example.com')
# SELECT users.* FROM users WHERE email LIKE 'peters@example.com'
```

```ruby
# These two calls are equivalent
User.objects.filter('zone::name': 'Jerusalem', email__isnull: false).count
User.objects.filter('zone::name': 'Jerusalem').exclude(email__exact: nil).count
```

## iexact

Case insensitive comparison but in the case the values is null, the comparison
will be generated with **IS NULL**.

```ruby
User.objects.filter('last_name__iexact': nil)
# SELECT users.* FROM users WHERE last_name IS NULL

User.objects.filter('last_name__iexact': 'De La Poer')
# SELECT users.* FROM users WHERE email ILIKE 'De La Poer'
```

## contains

Check if the value is contained in the field (case-sensitive match).

```ruby
User.objects.filter('last_name__contains': 'de la')
# SELECT users.* FROM users WHERE last_name LIKE '%de la%'
```

## icontains

Check if the value is contained in the field (case-insensitive match).

```ruby
User.objects.filter('last_name__contains': 'de la')
# SELECT users.* FROM users WHERE last_name ILIKE '%de la%'
```

## in

Check if the field is one of a series of elements.

```ruby
User.objects.filter('last_name__in': ['Magallanes', 'Gómez de Espinosa', 'Elcano'])
# SELECT users.* FROM users WHERE last_name IN ('Magallanes', 'Gómez de Espinosa', 'Elcano')
```

## gt

Greater than selection.

## gte

Greater than or equal selection.

## lt

Less than selection.

## lte

Less than or equal selection.

## startswith

Match those objects whose field starts with the value.

```ruby
User.objects.filter('last_name__startswith': 'Gómez')
# SELECT users.* FROM users WHERE last_name LIKE 'Gómez%'
```

## istartswith

Match those objects whose field starts with the value (case-insensitive).

```ruby
User.objects.filter('last_name__startswith': 'gómez')
# SELECT users.* FROM users WHERE last_name ILIKE 'gómez%'
```

## endswith

Match those objects whose field ends with the value.

```ruby
User.objects.filter('last_name__endswith': 'cano')
# SELECT users.* FROM users WHERE last_name LIKE '%cano'
```

## iendswith

Match those objects whose field ends with the value (case-insensitive).

```ruby
User.objects.filter('last_name__startswith': 'CaNo')
# SELECT users.* FROM users WHERE last_name ILIKE '%CaNo'
```

## between

Match those objects with a datetime field between two dates:

```ruby
User.objects.filter('created_at__between': [Time.zone.now - 3.days, Time.zone.now])
# SELECT users.* FROM users WHERE last_name between '2018-06-26 14:07:00' AND '2018-06-29 14:07:00'
```

## range

Alias for [between](#between).

## regex

Math ActiveRecord objects by regex expression.

```ruby
Post.objects.filter('first_name__regex': /\d+ stars/)
# SELECT * FROM posts WHERE title REGEXP BINARY '\\d+ stars'; -- MySQL
# SELECT * FROM posts WHERE title ~ '\\d+ stars'; -- PostgreSQL
# SELECT * FROM posts WHERE title REGEXP '^\\d+ stars'; -- SQLite
```

## iregex

Math ActiveRecord objects by regex expression (case-insensitive).

```ruby
Post.objects.filter('first_name__iregex': /\d+ stars/)
# SELECT * FROM posts WHERE title REGEXP '\\d+ stars'; -- MySQL
# SELECT * FROM posts title ~* '\\d+ stars'; -- PostgreSQL
# SELECT * FROM posts title REGEXP '(?i)\\d+ stars'; -- SQLite
```