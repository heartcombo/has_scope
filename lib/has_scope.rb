module HasScope
  TRUE_VALUES = ["true", true, "1", 1]

  ALLOWED_TYPES = {
    :array   => [[ Array ]],
    :hash    => [[Hash, ActionController::Parameters]],
    :boolean => [[ Object ], -> v { TRUE_VALUES.include?(v) }],
    :default => [[ String, Numeric ]],
  }

  def self.included(base)
    base.class_eval do
      extend ClassMethods
      class_attribute :scopes_configuration, :instance_writer => false
      self.scopes_configuration = {}
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
    # * <tt>:using</tt> - If type is a hash, you can provide :using to convert the hash to
    #                     a named scope call with several arguments.
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
    # * <tt>:allow_blank</tt> - Blank values are not sent to scopes by default. Set to true to overwrite.
    #
    # * <tt>:in</tt> - A shortcut for combining the :using option with nested hashes.
    #                  For example, "has_scope xyz, :in => :abc" is the same as
    #                  "has_scope xyz, :as => :abc, :using => :xyz, :type => :hash",
    #                  and would make the scope apply when the params are
    #                  "?abc[xyz]=value".
    #
    # * <tt>:if_value</tt> - For string and numeric types, indicates the value
    #                        that the param must have if the scope should apply.
    #
    # * <tt>:unless_value</tt> - For string and numeric types, indicates the
    #                            value that the param must have if the scope
    #                            should NOT apply.
    #
    # * <tt>:no_value_passing</tt> - Does not pass the value of the param to the
    #                                scope. Often used with :if_value and
    #                                :unless_value if the value is just used to
    #                                determine which scope is active.
    #
    # * <tt>:scope_by_value</tt> - A shortcut for combining :no_value_passing,
    #                              :as, and :if_value. :as is set to the value
    #                              provided to this option, and :if_value is set
    #                              to the scope name.
    #                              For example,
    #                              "has_scope xyz, :scope_by_value => :filter"
    #                              is the same as
    #                              "has_scope xyz, :as => :filter, :if_value => :xyz, :no_value_passing => true"
    # == Block usage
    #
    # has_scope also accepts a block. The controller, current scope and value are yielded
    # to the block so the user can apply the scope on its own. This is useful in case we
    # need to manipulate the given value:
    #
    #   has_scope :category do |controller, scope, value|
    #     value != "all" ? scope.by_category(value) : scope
    #   end
    #
    #   has_scope :not_voted_by_me, :type => :boolean do |controller, scope|
    #     scope.not_voted_by(controller.current_user.id)
    #   end
    #
    def has_scope(*scopes, &block)
      options = scopes.extract_options!
      options.symbolize_keys!
      options.assert_valid_keys(
          :type, :only, :except, :if, :unless, :default, :as, :using,
          :allow_blank, :in, :if_value, :unless_value, :scope_by_value,
          :no_value_passing)

      if options.key?(:scope_by_value)
        ensure_options_compatible!(:scope_by_value, [:if_value, :as], options)

        options[:as] = options[:scope_by_value]
        options[:no_value_passing] = true unless options.key?(:no_value_passing)
      end

      if options.key?(:in)
        ensure_options_compatible!(:in, [:scope_by_value, :as, :using], options)

        options[:as] = options[:in]
        options[:using] = scopes
      end

      if options.key?(:using)
        if options.key?(:type) && options[:type] != :hash
          raise "You cannot use :using with another :type different than :hash"
        else
          options[:type] = :hash
        end

        options[:using] = Array(options[:using])
      end

      options[:only]          = Array(options[:only])
      options[:except]        = Array(options[:except])
      options[:if_value]      = Array(options[:if_value])
      options[:unless_value]  = Array(options[:unless_value])

      self.scopes_configuration = scopes_configuration.dup

      scopes.each do |scope|
        scopes_configuration[scope] ||= { :as => scope, :type => :default, :block => block, :no_value_passing => false }
        scopes_configuration[scope] = self.scopes_configuration[scope].merge(options)
      end
    end

    # Checks whether the provided options contain any other options that
    # conflict with the current option being processed.
    def ensure_options_compatible!(current_option, incompatible_options, provided_options)
      incompatible_options.each {|key_name|
        if provided_options.key?(key_name)
          raise "You cannot use #{key_name} with #{current_option}"
        end
      }
    end
  end

  protected

  # Receives an object where scopes will be applied to.
  #
  #   class GraduationsController < InheritedResources::Base
  #     has_scope :featured, :type => true, :only => :index
  #     has_scope :by_degree, :only => :index
  #
  #     def index
  #       @graduations = apply_scopes(Graduation).all
  #     end
  #   end
  #
  def apply_scopes(target, hash=params)
    scopes_configuration.each do |scope, options|
      next unless apply_scope_to_action?(options)
      key = options[:as]

      if hash.key?(key)
        value, call_scope = hash[key], true
      elsif options.key?(:default)
        value, call_scope = options[:default], true
        if value.is_a?(Proc)
          value = value.arity == 0 ? value.call : value.call(self)
        end
      end

      value = parse_value(options[:type], key, value)
      value = normalize_blanks(value)

      if call_scope && (value.present? || options[:allow_blank]) && value_matches?(scope, value, options)
        current_scopes[key] = value
        target = call_scope_by_type(options[:type], scope, target, value, options)
      end
    end

    target
  end

  # Set the real value for the current scope if type check.
  def parse_value(type, key, value) #:nodoc:
    klasses, parser = ALLOWED_TYPES[type]
    if klasses.any? { |klass| value.is_a?(klass) }
      parser ? parser.call(value) : value
    end
  end

  # Screens pseudo-blank params.
  def normalize_blanks(value) #:nodoc:
    case value
    when Array
      value.select { |v| v.present? }
    when Hash
      value.select { |k, v| normalize_blanks(v).present? }.with_indifferent_access
    when ActionController::Parameters
      normalize_blanks(value.to_unsafe_h)
    else
      value
    end
  end

  # Call the scope taking into account its type.
  def call_scope_by_type(type, scope, target, value, options) #:nodoc:
    block = options[:block]

    if (type == :boolean && !options[:allow_blank]) || options[:no_value_passing]
      block ? block.call(self, target) : target.send(scope)
    elsif value && options.key?(:using)
      value = value.values_at(*options[:using])
      block ? block.call(self, target, value) : target.send(scope, *value)
    else
      block ? block.call(self, target, value) : target.send(scope, value)
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

  # Evaluates the scope options :scope_by_value, :if_value and :unless_value.
  # Returns true either if none of those options are being used, or if the value
  # of the options matches the appropriate value from the query string parameter.
  def value_matches?(scope, value, options)
    if value && options.key?(:using)
      value = value.values_at(*options[:using])
    end

    # Only match the first string we're passed, in case caller is using
    # :using and the value ends up being an array.
    first_value = Array(value).first

    if options.key?(:scope_by_value)
      (first_value.to_sym == scope.to_sym) unless first_value.nil?
    else
      result = true

      unless options[:if_value].empty?
        result = result && options[:if_value].include?(first_value.to_sym)
      end

      unless options[:unless_value].empty?
        result = result && !options[:unless_value].include?(first_value.to_sym)
      end

      result
    end
  end

  # Returns the scopes used in this action.
  def current_scopes
    @current_scopes ||= {}
  end
end

ActiveSupport.on_load :action_controller do
  include HasScope
  helper_method :current_scopes if respond_to?(:helper_method)
end
