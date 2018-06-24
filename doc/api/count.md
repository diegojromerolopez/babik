# Count

Call count method to return the number of ActiveRecord objects that match the filter.

## Aliases

- length

## Examples

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