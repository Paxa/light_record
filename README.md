LightRecord
===========

[![Build Status](https://travis-ci.org/Paxa/light_record.svg?branch=master)](https://travis-ci.org/Paxa/light_record)

ActiveRecord extension to kick the speed of allocating ActiveRecord object

### How it works

It provides functionality to load ActiveRecord records with patched attribute related methods.
This make AR objects as read-only but it makes up to 5 times less object allocations.

Each time when you retrieve objects via `.light_records` it will create annonymous class to work with given set of attributes.

```
  LightRecord Extension Class
              ↓
        Your AR Model
              ↓
      ActiveRecord::Base
```


### Installation

```ruby
gem 'light_record', github: 'paxa/light_record'
```

#### `scope.light_records`

```ruby
records = User.limit(1_000_000).light_records
records # => array of records. Very fast and very memory efficient
```

Idea is to skip all magic related to attributes and object initialization. This creates new class inherited from your model. That allows us to create only one extra object when we initialize new record.


Simply it become something like this:

```ruby
class User_light_record < User
  def initialize(attributes)
    @attributes = attributes # hash of data "as is" from database library
  end

  def email
    @attributes[:email]
  end
end
```


#### `scope.light_records_each`


Other method: `.light_records_each`, it will utilize `stream: true` feature from mysql2 client. So it will initialize objects one by one for every interation:

```ruby
User.limit(1_000_000).light_records_each do |user|
  user.do_something
end
```

This allow you to interate big amount of data without using `find_each` or `find_in_batches` because with `light_records_each` it will use very low memory. Or allow you to use `find_in_batches` with bigger batch size

\* Please note that time will be as a ruby [Time](http://ruby-doc.org/core-2.3.0/Time.html) object, instead of [TimeWithZone](http://api.rubyonrails.org/classes/ActiveSupport/TimeWithZone.html). To make it in correct timezone you can call it as:

```ruby
record.created_at.in_time_zone(Time.zone)
```

#### Benchmarks

Still on a way,
but I try to use in some project and it gives 3-5 times improvement, and 2-3 times less memory usage


---

Sometimes this can break functionality because it will override attribute methods and disable some of features in activerecord.

There is mechanism to override attribute methods created by LightRecord:

```ruby
class User < ActiveRecord::Base
  # this module will be included in extending class when we use light_records and light_records_each
  module LightRecord
    def sometihng
    end
  end
end
```

Note: when you use LightRecord instances it will break type casting

This gem supports MySQL and PostgreSQL
