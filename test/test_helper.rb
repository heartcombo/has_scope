require 'rubygems'

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

HasScope::Router = ActionDispatch::Routing::RouteSet.new
HasScope::Router.draw do |map|
  map.connect ':controller/:action/:id'
  map.connect ':controller/:action'
end

class ActiveSupport::TestCase
  setup do
    @router = HasScope::Router
  end
end
