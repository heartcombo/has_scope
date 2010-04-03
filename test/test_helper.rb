require 'rubygems'

gem 'activesupport', '3.0.0.beta2'
gem 'actionpack', '3.0.0.beta2'

begin
  gem "test-unit"
rescue LoadError
end

begin
  gem "ruby-debug"
  require 'ruby-debug'
rescue LoadError
end

require 'test/unit'
require 'mocha'

ENV["RAILS_ENV"] = "test"
RAILS_ROOT = "anywhere"

require 'active_support'
require 'action_controller'
require 'action_dispatch/middleware/flash'

class ApplicationController < ActionController::Base; end

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'has_scope'

HasScope::Routes = ActionDispatch::Routing::RouteSet.new
HasScope::Routes.draw do |map|
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
end

class ActiveSupport::TestCase
  setup do
    @routes = HasScope::Routes
  end
end
