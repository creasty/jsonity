Jsonity
=======

**The most sexy language for building JSON in Ruby**

I'd been writing JSON API with [Jbuilder](https://github.com/rails/jbuilder), [RABL](https://github.com/nesquena/rabl) and [ActiveModel::Serializer](https://github.com/rails-api/active_model_serializers), but nothing of them meet my requirement and use case.

- Jbuilder is very verbose in syntax, and its functonalities of partial and mixin are actually weak
- RABL has simple syntax, but writing complex data structure with it is not very readable
- ActiveModel::Serializer is persuasive role in Rails architecture, but can get very useless when you need to fully control from controller what attributes of multi-nested (associated) object to be included

So I chose to create new one -- Jsonity, which is simple and powerful JSON builder especially for JSON API representations.

- Simple and readable syntax even if it gets complex
- Flexible and arbitrary nodes
- Includable mixin
- Declarative attributes inclusion


Installation
------------

Make sure to add the gem to your Gemfile.

```ruby
gem 'jsonity'
```


Overview
--------

```ruby
@meta_pagination_mixin = ->(t) {
  t.meta! { |meta|
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

### Data object assignment

To declare the data object for use:

```ruby
Jsonity.build { |t|
  t <= @user
  # ...
}
```

Or passing as an argument:

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

  # or with specified the data object
  user.hello('world') { |w| w.upcase }

  # block can be omitted if the value is constant
  user.seventeen 17
}
=begin
{
  "full_name": "John Smith",
  "russian_roulette": 4,
  "hello": "WORLD",
  "seventeen": 17
}
=end
```

Aliased attributes works well as you expected:
 
```ruby
Jsonity.build(@user) { |user|
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
{
  "name": "John Smith",
  "avatar": {
    "image_url": "http://www.example.com/avatar.png",
    "width": 512,
    "height": 512
  }
}
=end
```

Assume that `@user.avatar` is `nil`, the output will be:

```ruby
=begin
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

To specify the data object to use inside a block:

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

Or a block can inherit the parent data object:

```ruby
Jsonity.build { |t|
  t.user!(@user) { |user|
    user.profile!(inherit: true) { |profile|
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

Also passing the data object or inheritance can be done in the same way as hash nodes.

### Automatic attributes inclusion

If you set `attr_json` in any class, **the specified attributes will automatically be included**:

```ruby
class Sample < Struct.new(:id, :foo, :bar)
  attr_json :id, :foo

  attr_json { |sample|
    sample.hello_from 'attr_json!'
  }
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
    "foo": "foo!",
    "hello_from": "attr_json!"
  }
}
=end
```

Still you can create any kinds of nodes with a block:

```ruby
Jsonity.build { |t|
  t.sample!(@sample) { |sample|
    sample.bar { |s| "this is #{s.bar}" }
  }
}
=begin
{
  "sample": {
    "id": 123,
    "foo": "foo!",
    "hello_from": "attr_json!",
    "bar": "this is bar!!"
  }
}
=end
```

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

To explicitly **specify the data object to use** in mixin, you can do by passing it in the first argument:

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

So you can take this functonality for **scope**:

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


### Using data object

You can get the data object as a second block parameter.

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
