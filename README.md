## HasScope

[![Gem Version](https://fury-badge.herokuapp.com/rb/has_scope.svg)](http://badge.fury.io/rb/has_scope)

_HasScope_ allows you to dynamically apply named scopes to your resources based on an incoming set of parameters.

The most common usage is to map incoming controller parameters to named scopes for filtering resources, but it can be used anywhere.

## Installation

Add `has_scope` to your bundle

```ruby
bundle add has_scope
```

or add it manually to your Gemfile if you prefer.

```ruby
gem 'has_scope'
```

## Examples

For the following examples we'll use a model called graduations:

```ruby
class Graduation < ActiveRecord::Base
  scope :featured, -> { where(featured: true) }
  scope :by_degree, -> degree { where(degree: degree) }
  scope :by_period, -> started_at, ended_at { where("started_at = ? AND ended_at = ?", started_at, ended_at) }
end
```

### Usage 1: Rails Controllers

_HasScope_ exposes the `has_scope` method automatically in all your controllers. This is used to declare the scopes a controller action can use to filter a resource:

```ruby
class GraduationsController < ApplicationController
  has_scope :featured, type: :boolean
  has_scope :by_degree
  has_scope :by_period, using: %i[started_at ended_at], type: :hash
end
```

To apply the scopes to a specific resource, you just need to call `apply_scopes`:

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

Then for each request to the `index` action, _HasScope_ will automatically apply the scopes as follows:

``` ruby
# GET /graduations
# No scopes applied
#=> brings all graduations
apply_scopes(Graduation).all == Graduation.all

# GET /graduations?featured=true
# The "featured' scope is applied
#=> brings featured graduations
apply_scopes(Graduation).all == Graduation.featured

# GET /graduations?by_period[started_at]=20100701&by_period[ended_at]=20101013
#=> brings graduations in the given period
apply_scopes(Graduation).all == Graduation.by_period('20100701', '20101013')

# GET /graduations?featured=true&by_degree=phd
#=> brings featured graduations with phd degree
apply_scopes(Graduation).all == Graduation.featured.by_degree('phd')

# GET /graduations?finished=true&by_degree=phd
#=> brings only graduations with phd degree because we didn't declare finished in our controller as a permitted scope
apply_scopes(Graduation).all == Graduation.by_degree('phd')
```

#### Check for currently applied scopes

_HasScope_ creates a helper method called `current_scopes` to retrieve all the scopes applied. As it's a helper method, you'll be able to access it in the controller action or the view rendered in that action.

Coming back to one of the examples above:

```ruby
# GET /graduations?featured=true&by_degree=phd
#=> brings featured graduations with phd degree
apply_scopes(Graduation).all == Graduation.featured.by_degree('phd')
```

Calling `current_scopes` after `apply_scopes` in the controller action or view would return the following:

```
current_scopes
#=> { featured: true, by_degree: 'phd' }
```

### Usage 2: Standalone Mode

_HasScope_ can also be used in plain old Ruby objects (PORO). To implement the previous example using this approach, create a bare object and include `HasScope` to get access to its features:

> Note: We'll create a simple version of a query object for this example as this type of object can have multiple different implementations.


```ruby
class GraduationsSearchQuery
  include HasScope
  # ...
end
```

Next, declare the scopes to be used the same way:

```ruby
class GraduationsSearchQuery
  include HasScope

  has_scope :featured, type: :boolean
  has_scope :by_degree
  has_scope :by_period, using: %i[started_at ended_at], type: :hash
  # ...
end
```

Now, allow your object to perform the query by exposing a method that will use `apply_scopes`:

```ruby
class GraduationsSearchQuery
  include HasScope

  has_scope :featured, type: :boolean
  has_scope :by_degree
  has_scope :by_period, using: %i[started_at ended_at], type: :hash

  def perform(collection: Graduation, params: {})
    apply_scopes(collection, params)
  end
end
```

Note that `apply_scopes` receives a `Hash` as a second argument, which represents the incoming params that determine which scopes should be applied to the model/collection. It defaults to `params` for compatibility with controllers, which is why it's not necessary to pass that second argument in the controller context.

Now in your controller you can call the `GraduationsSearchQuery` with the incoming parameters from the controller:

```ruby
class GraduationsController < ApplicationController
  def index
    graduations_query = GraduationsSearchQuery.new
    @graduations = graduations_query.perform(collection: Graduation, params: params)
  end
end
```

#### Accessing `current_scopes`

In the controller context, `current_scopes` is made available as a helper method to the controller and view, but it's a `protected` method of _HasScope_'s implementation, to prevent it from becoming publicly accessible outside of _HasScope_ itself. This means that the object implementation showed above has access to `current_scopes` internally, but it's not exposed to other objects that interact with it.

If you need to access `current_scopes` elsewhere, you can change the method visibility like so:

```ruby
class GraduationsSearchQuery
  include HasScope

  # ...

  public :current_scopes

  # ...
end
```

## Options

`has_scope` supports several options:

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

`has_scope` also accepts a block in case we need to manipulate the given value and/or call the scope in some custom way. Usually three arguments are passed to the block:
- The instance of the controller or object where it's included
- The current scope chain
- The value of the scope to apply

> 💡 We suggest you name the first argument depending on how you're using _HasScope_. If it's the controller, use the word "controller". If it's a query object for example, use "query", or something meaningful for that context (or simply use "context"). In the following examples, we'll use controller for simplicity.

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

## License

MIT License. Copyright 2020-2023 Rafael França, Carlos Antônio da Silva. Copyright 2009-2019 Plataformatec.
