module HasScope
  TRUE_VALUES = ["true", true, "1", 1]

  ALLOWED_TYPES = {
    :array   => [ Array ],
    :hash    => [ Hash ],
    :default => [ String, Numeric ]
  }

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
    # == Options
    #
    # * <tt>:type</tt> - Checks the type of the parameter sent. If set to :boolean
    #                    it just calls the named scope, without any argument. By default,
    #                    it does not allow hashes or arrays to be given, except if type
    #                    :hash or :array are set.
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
    #                       is always called.
    #
    def has_scope(*scopes)
      options = scopes.extract_options!
      options.symbolize_keys!

      if options.delete(:boolean)
        options[:type] ||= :boolean
        ActiveSupport::Deprecation.warn(":boolean => true is deprecated, use :type => :boolean instead", caller)
      end
      options.assert_valid_keys(:type, :only, :except, :if, :unless, :default, :as)

      options[:only]   = Array(options[:only])
      options[:except] = Array(options[:except])

      scopes.each do |scope|
        self.scopes_configuration[scope] ||= { :as => scope, :type => :default }
        self.scopes_configuration[scope].merge!(options)
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
  def apply_scopes(target)
    self.scopes_configuration.each do |scope, options|
      next unless apply_scope_to_action?(options)
      key = options[:as]

      if params.key?(key)
        value, call_scope = params[key], true
      elsif options.key?(:default)
        value, call_scope = options[:default], true
        value = value.call(self) if value.is_a?(Proc)
      end

      target = apply_scope_by_type(options[:type], key, scope, value, target) if call_scope
    end

    target
  end

  # Apply the scope taking into account its type.
  def apply_scope_by_type(type, key, scope, value, target) #:nodoc:
    if type == :boolean
      current_scopes[key] = TRUE_VALUES.include?(value)
      current_scopes[key] ? target.send(scope) : target
    elsif ALLOWED_TYPES[type].none?{ |klass| value.is_a?(klass) }
      raise "Expected type :#{type} in params[:#{key}], got :#{value.class}"
    else
      current_scopes[key] = value
      target.send(scope, value)
    end
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