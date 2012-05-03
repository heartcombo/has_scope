## HasScope

Has scope allows you to easily create controller filters based on your resources named scopes.
Imagine the following model called graduations:

```ruby
class Graduation < ActiveRecord::Base
  named_scope :featured, :conditions => { :featured => true }
  named_scope :by_degree, proc {|degree| { :conditions => { :degree => degree } } }
end
```

You can use those named scopes as filters by declaring them on your controller:

```ruby
class GraduationsController < ApplicationController
  has_scope :featured, :type => :boolean
  has_scope :by_degree
end
```

Now, if you want to apply them to an specific resource, you just need to call `apply_scopes`:

```ruby
class GraduationsController < ApplicationController
  has_scope :featured, :type => :boolean
  has_scope :by_degree
  has_scope :by_period, :using => [:started_at, :ended_at]

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

/graduations?params[by_period][started_at]=20100701&params[by_period][ended_at]=20101013
#=> brings graduations in the given period

/graduations?featured=true&by_degree=phd
#=> brings featured graduations with phd degree
```

You can retrieve all the scopes applied in one action with `current_scopes` method.
In the last case, it would return: { :featured => true, :by_degree => "phd" }.

## Installation

HasScope is available as gem on Gemcutter, so just run the following:

```
sudo gem install has_scope
```

If you want it as plugin, just do:

```
script/plugin install git://github.com/plataformatec/has_scope.git
```

## Options

HasScope supports several options:

* `:type` - Checks the type of the parameter sent. If set to :boolean it just calls the named scope, without any argument. By default, it does not allow hashes or arrays to be given, except if type :hash or :array are set.

* `:only` - In which actions the scope is applied.

* `:except` - In which actions the scope is not applied.

* `:as` - The key in the params hash expected to find the scope. Defaults to the scope name.

* `:using` - The subkeys to be used as args when type is a hash.

* `:if` - Specifies a method, proc or string to call to determine if the scope should apply.

* `:unless` - Specifies a method, proc or string to call to determine if the scope should NOT apply.

* `:default` - Default value for the scope. Whenever supplied the scope is always called.

* `:allow_blank` - Blank values are not sent to scopes by default. Set to true to overwrite.

## Block usage

has_scope also accepts a block. The controller, current scope and value are yielded
to the block so the user can apply the scope on its own. This is useful in case we
need to manipulate the given value:

```ruby
has_scope :category do |controller, scope, value|
  value != "all" ? scope.by_category(value) : scope
end
```

When used with booleans, it just receives two arguments and is just invoked if true is given:

```ruby
has_scope :not_voted_by_me, :type => :boolean do |controller, scope|
  scope.not_voted_by(controller.current_user.id) 
end
```

## Bugs and Feedback

If you discover any bugs or want to drop a line, feel free to create an issue on GitHub.

http://github.com/plataformatec/has_scope/issues

MIT License. Copyright 2009 Plataforma Tecnologia. http://blog.plataformatec.com.br
