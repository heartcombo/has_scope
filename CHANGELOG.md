## Unreleased

* Add support for Rails 7.0 and Ruby 3.1/3.2 (no changes required)
* Remove test files from the gem package.

## 0.8.0

* Fix usage of `:in` when defined with a `:default` option that is not a hash, to apply the default when param is not given.
* Fix usage of `:in` incorrectly calling scopes when receiving a blank param value without `allow_blank` set.
* Deprecate passing a String to `if` and `unless` options, in order to stop using `eval` in code.
* Require `active_support` and `action_controller` explicitly to prevent possible `uninitialized constant` errors.
* Add support for Ruby 2.7 and 3.0, drop support for Ruby < 2.5.
* Add support for Rails 6.1, drop support for Rails < 5.2.
* Move CI to GitHub Actions.

## 0.7.2

* Added support Rails 5.2 and 6.0.

## 0.7.1

* Added support Rails 5.1.

## 0.7.0

* Added support Rails 5.
* Removed support for Rails `3.2` and `4.0` and Ruby `1.9.3` and `2.0.0`.

## 0.6.0

* Allow custom types and parsers
* Boolean scopes with `allow_blank: true` are called with values, working as any other scopes
* Add `:in` option: a shortcut for combining the `:using` option with nested hashes
* Support Rails 4.1 & 4.2, Ruby 2.2

## 0.6.0.rc

* Drop support for Rails 3.1 and Ruby 1.8, keep support for Rails 3.2
* Support for Rails 4.0 onward
