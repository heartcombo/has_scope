## HasScope

[![Gem Version](https://fury-badge.herokuapp.com/rb/has_scope.svg)](http://badge.fury.io/rb/has_scope)
[![Code Climate](https://codeclimate.com/github/heartcombo/has_scope.svg)](https://codeclimate.com/github/heartcombo/has_scope)

Has scope allows you to map incoming controller parameters to named scopes in your resources.
Imagine the following model called graduations:

```ruby
class Graduation < ActiveRecord::Base
  scope :featured, -> { where(featured: true) }
  scope :by_degree, -> degree { where(degree: degree) }
  scope :by_period, -> started_at, ended_at { where("started_at = ? AND ended_at = ?", started_at, ended_at) }
end
```

You can use those named scopes as filters by declaring them on your controller:

```ruby
class GraduationsController < ApplicationController
  has_scope :featured, type: :boolean
  has_scope :by_degree
end
```

Now, if you want to apply them to an specific resource, you just need to call `apply_scopes`:

```ruby
class GraduationsController < ApplicationController
  has_scope :featured, type: :boolean
  has_scope :by_degree
  has_scope :by_period, using: %i[started_at ended_at], type: :hash

  def index
    @graduations = apply_scopes(Graduation).all
  end
end
```

Then for each request:

```
/graduations
#=> acts like a normal request

/graduations?featured=true
#=> calls the named scope and bring featured graduations

/graduations?by_period[started_at]=20100701&by_period[ended_at]=20101013
#=> brings graduations in the given period

/graduations?featured=true&by_degree=phd
#=> brings featured graduations with phd degree
```

You can retrieve all the scopes applied in one action with `current_scopes` method.
In the last case, it would return: `{ featured: true, by_degree: 'phd' }`.

## Installation

Add `has_scope` to your Gemfile or install it from Rubygems.

```ruby
gem 'has_scope'
```

## Options

HasScope supports several options:

* `:type` - Checks the type of the parameter sent.
  By default, it does not allow hashes or arrays to be given,
  except if type `:hash` or `:array` are set.
  Symbols are never permitted to prevent memory leaks, so ensure any routing
  constraints you have that add parameters use string values.

* `:only` - In which actions the scope is applied.

* `:except` - In which actions the scope is not applied.

* `:as` - The key in the params hash expected to find the scope. Defaults to the scope name.

* `:using` - The subkeys to be used as args when type is a hash.

* `:in` - A shortcut for combining the `:using` option with nested hashes.

* `:if` - Specifies a method or proc to call to determine if the scope should apply. Passing a string is deprecated and it will be removed in a future version.

* `:unless` - Specifies a method or proc to call to determine if the scope should NOT apply. Passing a string is deprecated and it will be removed in a future version.

* `:default` - Default value for the scope. Whenever supplied the scope is always called.

* `:allow_blank` - Blank values are not sent to scopes by default. Set to true to overwrite.

## Boolean usage

If `type: :boolean` is set it just calls the named scope, without any arguments, when parameter
is set to a "true" value. `'true'` and `'1'` are parsed as `true`, everything else as `false`.

When boolean scope is set up with `allow_blank: true`, it will call the scope with the value as
any usual scope.

```ruby
has_scope :visible, type: :boolean
has_scope :active, type: :boolean, allow_blank: true

# and models with
scope :visible, -> { where(visible: true) }
scope :active, ->(value = true) { where(active: value) }
```

_Note_: it is not possible to apply a boolean scope with just the query param being present, e.g.
`?active`, that's not considered a "true" value (the param value will be `nil`), and thus the
scope will be called with `false` as argument. In order for the scope to receive a `true` argument
the param value must be set to one of the "true" values above, e.g. `?active=true` or `?active=1`.

## Block usage

`has_scope` also accepts a block. The controller, current scope and value are yielded
to the block so the user can apply the scope on its own. This is useful in case we
need to manipulate the given value:

```ruby
has_scope :category do |controller, scope, value|
  value != 'all' ? scope.by_category(value) : scope
end
```

When used with booleans without `:allow_blank`, it just receives two arguments
and is just invoked if true is given:

```ruby
has_scope :not_voted_by_me, type: :boolean do |controller, scope|
  scope.not_voted_by(controller.current_user.id)
end
```

## Keyword arguments

Scopes with keyword arguments need to be called in a block:

```ruby
# in the model
scope :for_course, lambda { |course_id:| where(course_id: course_id) }

# in the controller
has_scope :for_course do |controller, scope, value|
  scope.for_course(course_id: value)
end
```

## Apply scope on every request

To apply scope on every request set default value and `allow_blank: true`:

```ruby
has_scope :available, default: nil, allow_blank: true, only: :show, unless: :admin?

# model:
scope :available, ->(*) { where(blocked: false) }
```

This will allow usual users to get only available items, but admins will
be able to access blocked items too.

## Check which scopes have been applied

To check which scopes have been applied, you can call `current_scopes` from the controller or view.
This returns a hash with the scope name as the key and the scope value as the value.

For example, if a boolean `:active` scope has been applied, `current_scopes` will return `{ active: true }`.

## Supported Ruby / Rails versions

We intend to maintain support for all Ruby / Rails versions that haven't reached end-of-life.

For more information about specific versions please check [Ruby](https://www.ruby-lang.org/en/downloads/branches/)
and [Rails](https://guides.rubyonrails.org/maintenance_policy.html) maintenance policies, and our test matrix.

## Bugs and Feedback

If you discover any bugs or want to drop a line, feel free to create an issue on GitHub.

MIT License. Copyright 2009-2019 Plataformatec. http://blog.plataformatec.com.br
