Jsonity
=======

**The most natural language for building JSON in Ruby**


Overview
--------

```ruby
@meta_pagination_mixin = ->(t) {
  t.meta!(inherit: true) { |meta|
    meta.total_pages
    meta.current_page
  }
}

Jsonity.build { |t|
  t[].users!(@users) { |user|
    user.id
    user.age
    user.full_name { |u| [u.first_name, u.last_name].join ' ' }

    user.avatar? { |avatar|
      avatar.image_url
    }
  }

  t.(@users, &@meta_pagination_mixin)
}
=begin
{
  "users": [
    {
      "id": 1,
      "age": 21,
      "full_name": "John Smith",
      "avatar": {
        "image_url": "http://example.com/john.png"
      }
    },
    {
      "id": 2,
      "age": 37,
      "full_name": "William Northington",
      "avatar": null
    }
  ],
  "meta": {
    "total_pages": 1,
    "current_page": 1
  }
}
=end
```


Usage
-----

Make sure to add the gem to your Gemfile.

```ruby
gem 'neo_json'
```

### Object assignment

To declare the data object for use:

```ruby
Jsonity.build { |t|
  t <= @user
  # ...
}
```

Or pass as an argument:

```ruby
Jsonity.build(@user) { |user|
  # ...
}
```


### Attribute nodes

Basic usage of defining simple attributes:

```ruby
Jsonity.build(@user) { |user|
  user.id   # @user.id
  user.age  # @user.age
}
=begin
{
  "id": 123,
  "age": 27
}
=end
```
 
Or you can use custom attributes in flexible ways:

```ruby
Jsonity.build(@user) { |user|
  # create full_name from @user.first_name and @user.last_name
  user.full_name { |u| [u.first_name, u.last_name].join ' ' }

  # block parameter isn't required
  user.russian_roulette { rand(1..10) }

  # or with specified object
  user.feature_time(Time.now) { |now| now + 1.years }

  # block can be omitted if the value is constant
  user.seventeen 17
}
=begin
{
  "full_name": "John Smith",
  "russian_roulette": 4,
  "feature_time": "2015-09-13 12:32:39 +0900",
  "seventeen": 17
}
=end
```

Aliased attributes works well as you expected:
 
```ruby
Jsonity.build(@user) { |user|
  # show `id` as `my_id`
  user.my_id &:id
}
=begin
{
  "my_id": 123
}
=end
```

### Hash nodes

With name suffixed with `!`, nested object can be included:

```ruby
Jsonity.build(@user) { |user|
  user.name  # @user.name

  user.avatar! { |avatar|
    avatar.image_url  # @user.avatar.image_url
    avatar.width      # @user.avatar.width
    avatar.height     # @user.avatar.height
  }
}
=begin
Assume that `@user.avatar` is `nil`,

{
  "name": "John Smith",
  "avatar": {
    "image_url": null,
    "width": null,
    "height": null
  }
}
=end
```

On the other hand, use `?` as suffix, the whole object become `null`:

```ruby
Jsonity.build(@user) { |user|
  user.name

  user.avatar? { |avatar|  # <-- look, prefix is `?`
    avatar.image_url
    avatar.width
    avatar.height
  }
}
=begin
Assume that `@user.avatar` is `nil`,

{
  "name": "John Smith",
  "avatar": null
}
=end
```

Explicitly specify an object to use inside a block:

```ruby
Jsonity.build { |t|
  t.home!(@user.hometown_address) { |home|
    home.street  # @user.hometown_address.street
    home.zip
    home.city
    home.state
  }
}
=begin
{
  "home": {
    "street": "4611 Armbrester Drive",
    "zip": "90017",
    "city": "Los Angeles",
    "state": "CA"
  }
}
=end
```

Or a block can inherit the parent object:

```ruby
Jsonity.build { |t|
  t.user!(@user) { |user|
    t.profile!(inherit: true) { |profile|
      profile.name  # @user.name
    }
  }
}
=begin
{
  "user": {
    "profile": {
      "name": "John Smith"
    }
  }
}
=end
```

### Automatic attributes inclusion

If you set `attr_json` in any class, **the specified attributes will automatically be included**:

```ruby
class Sample < Struct.new(:id, :foo, :bar)
  attr_json :id, :foo
end

@sample = Sample.new 123, 'foo!', 'bar!!'
```

and then,

```ruby
Jsonity.build { |t|
  t.sample! @sample
}
=begin
{
  "sample": {
    "id": 123,
    "foo": "foo!"
  }
}
=end
```

Still you can create any kinds of nodes with a block:

```ruby
Jsonity.build { |t|
  t.sample!(@sample) { |sample|
    sample.bar { |bar| "this is #{bar}" }
  }
}
=begin
{
  "sample": {
    "id": 123,
    "foo": "foo!",
    "bar": "this is bar!!"
  }
}
=end
```


### Array nodes

Including a collection of objects, just use `[]` and write the same syntax of hash node:

```ruby
Jsonity.build(@user) { |user|
  user[].friends! { |friend|
    friend.name  # @user.friends[i].name
  }
}
=begin
{
  "friends": [
    { "name": "John Smith" },
    { "name": "William Northington" }
  ]
}
=end
```

Similar to hash nodes in naming convention,  
if `@user.friends = nil` nodes suffix with `!` will be an empty array `[]`, in contrast, some with `?` will be `null`.

Also passing the object or inheritance can be done in the same way as hash nodes.


### Mixin / Scope

Since Jsonity aim to be simple and light, **use plain `Proc`** to fullfill functonality of mixin.

```ruby
@timestamps_mixin = ->(t) {
  t.created_at
  t.updated_at
}
```

and then,

```ruby
Jsonity.build { |t|
  t.user!(@user) { |user|
    user.(&@timestamps_mixin)
  }
}
=begin
{
  "user": {
    "created_at": "2014-09-10 10:41:07 +0900",
    "updated_at": "2014-09-13 12:55:56 +0900"
  }
}
=end
```

In case you might explicitly **specify an object to use** in mixin, you can do by passing it in the first argument:

```ruby
Jsonity.build { |t|
  t.(@user, &@timestamps_mixin)
}
=begin
{
  "created_at": "2014-09-10 10:41:07 +0900",
  "updated_at": "2014-09-13 12:55:56 +0900"
}
=end
```

So you take this functonality for **scope**:

```ruby
Jsonity.build { |t|
  t.(@user) { |user|
    user.name
  }
}
=begin
{
  "name": "John Smith"
}
=end
```

#### Mixining nested object and merging

```ruby
@meta_pagination_mixin = ->(t) {
  t.meta! { |meta|
    meta.total_pages
    meta.current_page
  }
}
```

and use this mixin like:

```ruby
Jsonity.build { |t|
  t.(@people, &@meta_pagination_mixin)

  t.meta! { |meta|
    meta.total_count @people.count
  }
}
=begin
Notice that two objects `meta!` got merged.

{
  "meta": {
    "total_pages": 5,
    "current_page": 1,
    "total_count": 123
  }
}
=end
```


### Using object

You can get the current object as a second block parameter.

```ruby
Jsonity.build { |t|
  t[].people!(@people) { |person, person_obj|
    unless person_obj.private_member?
      person.name
      person.age
    end

    person.cv if person_obj.looking_for_job?
  }
}
```


With Rails
----------

Helper method is available in controller for rendering with Jsonity:

```ruby
render_json(status: :ok) { |t|
  # ...
}
```


License
-------

This project is copyright by [Creasty](http://www.creasty.com), released under the MIT lisence.  
See `LICENSE` file for details.
