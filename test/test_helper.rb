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
require 'action_controller/test_case'
require 'action_controller/test_process'

class ApplicationController < ActionController::Base; end

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'has_scope'

ActionController::Routing::Routes.draw do |map|
  map.connect ':controller/:action/:id'
end