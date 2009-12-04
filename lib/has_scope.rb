module HasScope
  TRUE_VALUES = ["true", true, "1", 1]
  
  def self.included(base)
    base.class_eval do
      extend ClassMethods
      helper_method :current_scopes

      class_inheritable_accessor :scopes_configuration, :instance_writer => false
      self.scopes_configuration ||= {}
    end
  end

  module ClassMethods
    # Detects params from url and apply as scopes to your classes.
    #
    # Your model:
    #
    #   class Graduation < ActiveRecord::Base
    #     named_scope :featured, :conditions => { :featured => true }
    #     named_scope :by_degree, proc {|degree| { :conditions => { :degree => degree } } }
    #   end
    #
    # Your controller:
    #
    #   class GraduationsController < InheritedResources::Base
    #     has_scope :featured, :boolean => true, :only => :index
    #     has_scope :by_degree, :only => :index
    #   end
    #
    # Then for each request:
    #
    #   /graduations
    #   #=> acts like a normal request
    #
    #   /graduations?featured=true
    #   #=> calls the named scope and bring featured graduations
    #
    #   /graduations?featured=true&by_degree=phd
    #   #=> brings featured graduations with phd degree
    #
    # You can retrieve the current scopes in use with <tt>current_scopes</tt>
    # method. In the last case, it would return: { :featured => "true", :by_degree => "phd" }
    #
    # == Options
    #
    # * <tt>:boolean</tt> - When set to true, call the scope only when the param is true or 1,
    #                       and does not send the value as argument.
    #
    # * <tt>:only</tt> - In which actions the scope is applied. By default is :all.
    #
    # * <tt>:except</tt> - In which actions the scope is not applied. By default is :none.
    #
    # * <tt>:as</tt> - The key in the params hash expected to find the scope.
    #                  Defaults to the scope name.
    #
    # * <tt>:if</tt> - Specifies a method, proc or string to call to determine
    #                  if the scope should apply
    #
    # * <tt>:unless</tt> - Specifies a method, proc or string to call to determine
    #                      if the scope should NOT apply.
    #
    # * <tt>:default</tt> - Default value for the scope. Whenever supplied the scope
    #                       is always called. This is useful to add easy pagination.
    #
    def has_scope(*scopes)
      options = scopes.extract_options!
      options.symbolize_keys!
      options.assert_valid_keys(:boolean, :only, :except, :if, :unless, :default, :as)

      scopes.each do |scope|
        self.scopes_configuration[scope]         ||= {}
        self.scopes_configuration[scope][:as]      = options[:as] || scope
        self.scopes_configuration[scope][:only]    = Array(options[:only])
        self.scopes_configuration[scope][:except]  = Array(options[:except])

        [:if, :unless, :boolean, :default].each do |opt|
          self.scopes_configuration[scope][opt] = options[opt] if options.key?(opt)
        end
      end
    end
  end

  protected

  # Receives an object where scopes will be applied to.
  #
  #   class GraduationsController < InheritedResources::Base
  #     has_scope :featured, :boolean => true, :only => :index
  #     has_scope :by_degree, :only => :index
  #
  #     def index
  #       @graduations = apply_scopes(Graduation).all
  #     end
  #   end
  #
  def apply_scopes(target_object)
    self.scopes_configuration.each do |scope, options|
      next unless apply_scope_to_action?(options)
      key = options[:as]

      if params.key?(key)
        value, call_scope = params[key], true
      elsif options.key?(:default)
        value, call_scope = options[:default], true
        value = value.call(self) if value.is_a?(Proc)
      end

      if call_scope
        if options[:boolean]
          target_object = target_object.send(scope) if current_scopes[key] = TRUE_VALUES.include?(value)
        else
          current_scopes[key] = value
          target_object = target_object.send(scope, value)
        end
      end
    end

    target_object
  end

  # Given an options with :only and :except arrays, check if the scope
  # can be performed in the current action.
  def apply_scope_to_action?(options) #:nodoc:
    return false unless applicable?(options[:if], true) && applicable?(options[:unless], false)

    if options[:only].empty?
      options[:except].empty? || !options[:except].include?(action_name.to_sym)
    else
      options[:only].include?(action_name.to_sym)
    end
  end

  # Evaluates the scope options :if or :unless. Returns true if the proc
  # method, or string evals to the expected value.
  def applicable?(string_proc_or_symbol, expected) #:nodoc:
    case string_proc_or_symbol
      when String
        eval(string_proc_or_symbol) == expected
      when Proc
        string_proc_or_symbol.call(self) == expected
      when Symbol
        send(string_proc_or_symbol) == expected
      else
        true
    end
  end

  # Returns the scopes used in this action.
  def current_scopes
    @current_scopes ||= {}
  end
end

ApplicationController.send :include, HasScope