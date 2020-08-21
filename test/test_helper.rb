require 'bundler/setup'

require 'minitest/autorun'
require 'mocha'
require 'mocha/mini_test'

# Configure Rails
ENV['RAILS_ENV'] = 'test'

require 'active_support'
require 'active_support/core_ext/string/strip'
require 'action_controller'
require 'action_dispatch/middleware/flash'

$:.unshift File.expand_path('../../lib', __FILE__)
require 'has_scope'

HasScope::Routes = ActionDispatch::Routing::RouteSet.new
HasScope::Routes.draw do
  resources :trees, only: %i[index new edit show]
end

class ApplicationController < ActionController::Base
  include HasScope::Routes.url_helpers
end

class ActiveSupport::TestCase
  self.test_order = :random if respond_to?(:test_order=)

  setup do
    @routes = HasScope::Routes
  end
end
