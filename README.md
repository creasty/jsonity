Jsonity
=======

**The most natural language for building JSON in Ruby**


Overview
--------

```ruby
@meta_pagination = ->(t) {
  t.meta!(inherit: true) { |meta|
    meta.total_pages
    meta.current_page
  }
}

Jsonity.build { |t|
  t <= @users

  t[].users!(inherit: true) { |user|
    user.id
    user.age
    user.full_name { |u| [u.first_name, u.last_name].join ' ' }

    user.avatar? { |avatar|
      avatar.image_url
    }
  }

  t.(&@meta_pagination)
}
#=> {
#     "users": [
#       {
#         "id": 1,
#         "age": 21,
#         "full_name": "John Smith",
#         "avatar": {
#           "image_url": "http://example.com/john.png"
#         }
#       },
#       {
#         "id": 2,
#         "age": 37,
#         "full_name": "William Northington",
#         "avatar": {
#           "image_url": "http://example.com/william.png"
#         }
#       },
#       {
#         "id": 3,
#         "age": 29,
#         "full_name": "Samuel Miller",
#         "avatar": {
#           "image_url": "http://example.com/samuel.png"
#         }
#       }
#     ],
#     "meta": {
#       "total_pages": 1,
#       "current_page": 1
#     }
#   }
```


Usage
-----

Make sure to add the gem to your Gemfile.

```ruby
gem 'neo_json'
```

Start writing object:

```ruby
Jsonity.build { |t|
  # ...
}
```

### Object assignment

To declare the data object for use:

```ruby
t <= @user
```

### Attribute nodes

Basic usage of defining simple attributes:

```ruby
t.id   # @user.id
t.age  # @user.age
```
 
Or you can use custom attributes in flexible ways:

```ruby
t.full_name { |u| [u.first_name, u.last_name].join ' ' }  # u = @user
t.russian_roulette { rand(1..10) }                        # block parameter isn't required
t.with_object(Time) { |t| t.now }                         # now, t = Time
t.seventeen 17                                            # block can be omitted
```

Aliased attributes works well as you expected:
 
```ruby
# show `id` as `my_id`
t.my_id &:id
```

### Automatic attributes inclusion

If you set `attr_json` in any class, the specified attributes will automatically be included:

```ruby
class Sample < Struct.new(:id, :foo)
  attr_json :id, :foo
end

@sample = Sample.new 123, 'foo!'

Jsonity.build { |t|
  t.sample!(@sample) { |t|
    # leave empty inside
  }
}
#=> {
#     "sample": {
#       "id": 123,
#       "foo": "foo!"
#     }
#   }
```

### Hash nodes

With name suffixed with `!`, nested object can be included:

```ruby
t.user! { |user|
  user.name  # @user.name

  user.avatar! { |avatar|
    avatar.image_url  # @user.avatar.image_url
    avatar.width      # @user.avatar.width
    avatar.height     # @user.avatar.height
  }
}
```

If `@user.avatar = nil`, the output will be like this:

```javascipt
{
  "user": {
    "name": "John Smith",
    "avatar": {
      "image_url": null,
      "width": null,
      "height": null
    }
  }
}
```

On the other hand, use `?` as suffix, the whole object become `null`:

```ruby
t.user! { |user|
  user.name

  user.avatar? { |avatar|
    avatar.image_url
    avatar.width
    avatar.height
  }
}
```

and the output will be:

```javascipt
{
  "user": {
    "name": "John Smith",
    "avatar": null
  }
}
```

Explicitly set an object to use inside a block:

```ruby
t.home?(@user.hometown_address) { |home|
  home.street  # @user.hometown_address.street
  home.zip
  home.city
  home.state
}
```

Or blocks can inherit the parent object:

```ruby
t.user! { |user|
  t.my!(inherit: true) { |my|
    my.name  # @user.name
  }
}
```

### Array nodes

Including a collection of objects, just use `t[]` and write the same syntax of hash node:

```ruby
t[].friends! { |friend|
  friend.name
}
```

and the output JSON will be:

```javascipt
{
  "friends": [
    {
      name: "John Smith"
    }
  ]
}
```

Similar to hash nodes in naming convention,  
if `@user.friends = nil` nodes suffix with `!` will be an empty array `[]`, in contrast, some with `?` will be `null`.

Also passing the object or inheritance can be done in the same way as hash nodes.


### Mixin / Scope

Since Jsonity aim to be simple and light, use plain `Proc` to fullfill functonality of mixin.

```ruby
timestamp_mixin = ->(t) {
  t.created_at
  t.updated_at
}
```

and then,

```ruby
t.user! { |user|
  user.(&timestamp_mixin)
}
```

In case you might use different object in mixin, you can pass the object in the first argument:

```ruby
t.(@other_user, &timestamps)
```

So you take this functonality for scope:

```ruby
t.(@other_user) { |other_user|
  other_user.name
}
```

#### Mixining nested object and merging

```ruby
meta_pagination_mixin = ->(t) {
  t.meta! { |meta|
    meta.total_pages
    meta.current_page
  }
}
```

and use this mixin like:

```ruby
t[].people!(@people) { |person|
  # ...
}

t.(@people, &meta_pagination_mixin)

t.meta! { |meta|
  meta.total_count @people.count
}
```

the output become:

```javascript
{
  "people": [
    // ...
  ],
  "meta": {
    "total_pages": 5,
    "current_page": 1,
    "total_count": 123
  }
}
```

Notice that two objects `meta!` got merged.

### Conditions

Simply you can use `if` or `unless` statement inside the block:

```
t[].people! { |person|
  unless person.private_member?
    person.name
    person.age
  end

  person.cv if person.looking_for_job?
}
```


With Rails
----------

Helper method is available for rendering with Jsonity:

```ruby
render_json(status: :ok) { |t|
  # ...
}
```


License
-------

This project is copyright by [Creasty](http://www.creasty.com), released under the MIT lisence.  
See `LICENSE` file for details.
