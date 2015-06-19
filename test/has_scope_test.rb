require 'test_helper'

HasScope::ALLOWED_TYPES[:date] = [[String], -> v { Date.parse(v) rescue nil }]

class Tree; end

class TreesController < ApplicationController
  has_scope :color, :unless => :show_all_colors?
  has_scope :only_tall, :type => :boolean, :only => :index, :if => :restrict_to_only_tall_trees?
  has_scope :shadown_range, :default => 10, :except => [ :index, :show, :new ]
  has_scope :root_type, :as => :root, :allow_blank => true
  has_scope :planted_before, :default => proc { Date.today }
  has_scope :planted_after, :type => :date
  has_scope :calculate_height, :default => proc {|c| c.session[:height] || 20 }, :only => :new
  has_scope :paginate, :type => :hash
  has_scope :args_paginate, :type => :hash, :using => [:page, :per_page]
  has_scope :categories, :type => :array
  has_scope :title, :in => :q
  has_scope :content, :in => :q
  has_scope :conifer, type: :boolean, :allow_blank => true

  has_scope :only_short, :type => :boolean do |controller, scope|
    scope.only_really_short!(controller.object_id)
  end

  has_scope :by_category do |controller, scope, value|
    scope.by_given_category(controller.object_id, value + "_id")
  end

  def index
    @trees = apply_scopes(Tree).all
  end

  def new
    @tree = apply_scopes(Tree).new
  end

  def show
    @tree = apply_scopes(Tree).find(params[:id])
  end
  alias :edit :show

  protected
    def restrict_to_only_tall_trees?
      true
    end

    def show_all_colors?
      false
    end

    def default_render
      render :text => action_name
    end
end

class BonsaisController < TreesController
  has_scope :categories, :if => :categories?

  protected
    def categories?
      false
    end
end

class HasScopeTest < ActionController::TestCase
  tests TreesController

  def test_boolean_scope_is_called_when_boolean_param_is_true
    Tree.expects(:only_tall).with().returns(Tree).in_sequence
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :only_tall => 'true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :only_tall => true }, current_scopes)
  end

  def test_boolean_scope_is_not_called_when_boolean_param_is_false
    Tree.expects(:only_tall).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :only_tall => 'false'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_boolean_scope_with_allow_blank_is_called_when_boolean_param_is_true
    Tree.expects(:conifer).with(true).returns(Tree).in_sequence
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :conifer => 'true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :conifer => true }, current_scopes)
  end

  def test_boolean_scope_with_allow_blank_is_called_when_boolean_param_is_false
    Tree.expects(:conifer).with(false).returns(Tree).in_sequence
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :conifer => 'not_true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :conifer => false }, current_scopes)
  end

  def test_boolean_scope_with_allow_blank_is_not_called_when_boolean_param_is_not_present
    Tree.expects(:conifer).never
    Tree.expects(:all).returns([mock_tree])
    get :index
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_called_only_on_index
    Tree.expects(:only_tall).never
    Tree.expects(:find).with('42').returns(mock_tree)
    get :show, :only_tall => 'true', :id => '42'
    assert_equal(mock_tree, assigns(:tree))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_skipped_when_if_option_is_false
    @controller.stubs(:restrict_to_only_tall_trees?).returns(false)
    Tree.expects(:only_tall).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :only_tall => 'true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_skipped_when_unless_option_is_true
    @controller.stubs(:show_all_colors?).returns(true)
    Tree.expects(:color).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :color => 'blue'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_called_except_on_index
    Tree.expects(:shadown_range).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :shadown_range => 20
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_called_with_arguments
    Tree.expects(:color).with('blue').returns(Tree).in_sequence
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :color => 'blue'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :color => 'blue' }, current_scopes)
  end

  def test_scope_is_not_called_if_blank
    Tree.expects(:color).never
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :color => ''
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_called_when_blank_if_allow_blank_is_given
    Tree.expects(:root_type).with('').returns(Tree)
    Tree.expects(:all).returns([mock_tree]).in_sequence
    get :index, :root => ''
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :root => '' }, current_scopes)
  end

  def test_multiple_scopes_are_called
    Tree.expects(:only_tall).with().returns(Tree)
    Tree.expects(:color).with('blue').returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :color => 'blue', :only_tall => 'true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :color => 'blue', :only_tall => true }, current_scopes)
  end

  def test_scope_of_type_hash
    hash = { "page" => "1", "per_page" => "10" }
    Tree.expects(:paginate).with(hash).returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :paginate => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :paginate => hash }, current_scopes)
  end

  def test_scope_of_type_hash_with_using
    hash = { "page" => "1", "per_page" => "10" }
    Tree.expects(:args_paginate).with("1", "10").returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :args_paginate => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :args_paginate => hash }, current_scopes)
  end

  def test_hash_with_blank_values_is_ignored
    hash = { "page" => "", "per_page" => "" }
    Tree.expects(:paginate).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :paginate => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_nested_hash_with_blank_values_is_ignored
    hash = { "parent" => {"children" => ""} }
    Tree.expects(:paginate).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :paginate => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_nested_blank_array_param_is_ignored
    hash = { "parent" => [""] }
    Tree.expects(:paginate).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :paginate => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_of_type_array
    array = %w(book kitchen sport)
    Tree.expects(:categories).with(array).returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :categories => array
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :categories => array }, current_scopes)
  end

  def test_array_of_blank_values_is_ignored
    Tree.expects(:categories).never
    Tree.expects(:all).returns([mock_tree])
    get :index, :categories => [""]
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_of_invalid_type_silently_fails
    Tree.expects(:all).returns([mock_tree])
    get :index, :paginate => "1"
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ }, current_scopes)
  end

  def test_scope_is_called_with_default_value
    Tree.expects(:shadown_range).with(10).returns(Tree).in_sequence
    Tree.expects(:find).with('42').returns(mock_tree).in_sequence
    get :edit, :id => '42'
    assert_equal(mock_tree, assigns(:tree))
    assert_equal({ :shadown_range => 10 }, current_scopes)
  end

  def test_default_scope_value_can_be_overwritten
    Tree.expects(:shadown_range).with('20').returns(Tree).in_sequence
    Tree.expects(:find).with('42').returns(mock_tree).in_sequence
    get :edit, :id => '42', :shadown_range => '20'
    assert_equal(mock_tree, assigns(:tree))
    assert_equal({ :shadown_range => '20' }, current_scopes)
  end

  def test_scope_with_different_key
    Tree.expects(:root_type).with('outside').returns(Tree).in_sequence
    Tree.expects(:find).with('42').returns(mock_tree).in_sequence
    get :show, :id => '42', :root => 'outside'
    assert_equal(mock_tree, assigns(:tree))
    assert_equal({ :root => 'outside' }, current_scopes)
  end

  def test_scope_with_default_value_as_a_proc_without_argument
    Date.expects(:today).returns("today")
    Tree.expects(:planted_before).with("today").returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :planted_before => "today" }, current_scopes)
  end

  def test_scope_with_default_value_as_proc_with_argument
    session[:height] = 100
    Tree.expects(:calculate_height).with(100).returns(Tree).in_sequence
    Tree.expects(:new).returns(mock_tree).in_sequence
    get :new
    assert_equal(mock_tree, assigns(:tree))
    assert_equal({ :calculate_height => 100 }, current_scopes)
  end

  def test_scope_with_custom_type
    parsed = Date.civil(2014,11,11)
    Tree.expects(:planted_after).with(parsed).returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :planted_after => "2014-11-11"
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :planted_after => parsed }, current_scopes)
  end

  def test_scope_with_boolean_block
    Tree.expects(:only_really_short!).with(@controller.object_id).returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :only_short => 'true'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :only_short => true }, current_scopes)
  end

  def test_scope_with_other_block_types
    Tree.expects(:by_given_category).with(@controller.object_id, 'for_id').returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :by_category => 'for'
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :by_category => 'for' }, current_scopes)
  end

  def test_scope_with_nested_hash_and_in_option
    hash = { 'title' => 'the-title', 'content' => 'the-content' }
    Tree.expects(:title).with('the-title').returns(Tree)
    Tree.expects(:content).with('the-content').returns(Tree)
    Tree.expects(:all).returns([mock_tree])
    get :index, :q => hash
    assert_equal([mock_tree], assigns(:trees))
    assert_equal({ :q => hash }, current_scopes)
  end

  def test_overwritten_scope
    assert_nil(TreesController.scopes_configuration[:categories][:if])
    assert_equal(:categories?, BonsaisController.scopes_configuration[:categories][:if])
  end

  protected

    def mock_tree(stubs={})
      @mock_tree ||= mock(stubs)
    end

    def current_scopes
      @controller.send :current_scopes
    end
end

class TreeHugger
  include HasScope

  has_scope :color

  def by_color
    apply_scopes(Tree, :color => 'blue')
  end

end

class HasScopeOutsideControllerTest < ActiveSupport::TestCase

  def test_has_scope_usable_outside_controller
    Tree.expects(:color).with('blue')
    TreeHugger.new.by_color
  end

end
