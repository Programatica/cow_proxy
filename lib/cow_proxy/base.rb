module CowProxy
  # Base class to create CowProxy classes
  #
  # Also, it's used as default CowProxy class for non-registered classes
  # with copy-on-write disabled, so returned values are wrapped but
  # methods trying to change object still raise exception.
  class Base
    class << self
      # Class which will be wrapped with this CowProxy class
      attr_accessor :wrapped_class

      # Setup wrapped_class and register itself into CowProxy
      # with {CowProxy.register_proxy CowProxy.register_proxy}
      def inherited(subclass)
        subclass.wrapped_class = wrapped_class
        CowProxy.register_proxy wrapped_class, subclass if wrapped_class
      end

      protected
      # Return block with proxy implementation.
      #
      # Block calls a method in wrapped object
      #
      # @param [Symbol] method Method name to call in wrapped object
      # @param [Boolean] cow_enabled True if copy-on-write is enabled
      #   for proxy class, it will _copy_on_write when method will
      #   modify wrapped object.
      # @return [Proc] Block with proxy implementation.
      def wrapping_block(method, cow_enabled)
        lambda do |*args, &block|
          inst_var = "@#{method}" if method.to_s =~ /^\w+$/
          return _instance_variable_get(inst_var) if inst_var && _instance_variable_defined?(inst_var)
          if method.to_s =~ /^(\w+)=$/ && _instance_variable_defined?("@#{$1}")
            CowProxy.debug { "remove #{$1}" }
            _remove_instance_variable "@#{$1}"
          end
          __wrapped_method__(inst_var, cow_enabled, method, *args, &block)
        end
      end
    end

    # Creates a CowProxy object wrapping obj
    #
    # @param obj An object to wrap with CowProxy class
    # @param parent CowProxy object wrapping obj
    # @param parent_var instance variable name in parent
    #   which keeps this CowProxy object
    def initialize(obj, parent = nil, parent_var = nil)
      @delegate_dc_obj = obj
      @parent_proxy = parent
      @parent_var = parent_var
      @dc_obj_duplicated = false
    end

    protected
    # Replace wrapped object with a copy, so object can
    # be modified.
    #
    # @param [Boolean] parent Replace proxy object in parent with
    #   duplicated wrapped object, if this proxy was created from
    #   another CowProxy.
    # @return duplicated wrapped object
    def __copy_on_write__(parent = true)
      CowProxy.debug { "copy on write on #{__getobj__.class.name}" }
      return @delegate_dc_obj if @dc_obj_duplicated
      @delegate_dc_obj = @delegate_dc_obj.dup.tap do |new_target|
        @dc_obj_duplicated = true
        if parent && @parent_proxy
          @parent_proxy.send :__copy_on_write__, false
          if @parent_var
            parent_dc = @parent_proxy._instance_variable_get(:@delegate_dc_obj)
            method = @parent_var[1..-1] + '='
            parent_dc.send(method, new_target)
          end
        end
      end
    end

    private
    def __getobj__
      @delegate_dc_obj
    end

    def __wrap__(value, inst_var = nil)
      if value.frozen?
        CowProxy.debug { "wrap #{value.class.name} with parent #{__getobj__.class.name}" }
        wrap_klass = CowProxy.wrapper_class(value)
        wrap_value = wrap_klass.new(value, self, inst_var) if wrap_klass
        _instance_variable_set(inst_var, wrap_value) if inst_var && wrap_value
        wrap_value
      end
    end

    def __wrapped_value__(inst_var, method, *args, &block)
      CowProxy.debug { "run on #{__getobj__.class.name} (#{__getobj__.object_id}) #{method} #{args.inspect unless args.empty?}" }
      value = __getobj__.__send__(method, *args, &block)
      wrap_value = __wrap__(value, inst_var) if inst_var && args.empty? && block.nil?
      wrap_value || value
    end

    def __wrapped_method__(inst_var, cow, method, *args, &block)
      __wrapped_value__(inst_var, method, *args, &block)
    rescue => e
      CowProxy.debug { "error #{e.message} on #{__getobj__.class.name} (#{__getobj__.object_id}) #{method} #{args.inspect unless args.empty?} with#{'out' unless cow} cow" }
      raise unless cow && e.message =~ /^can't modify frozen/
      CowProxy.debug { "copy on write to run #{method} #{args.inspect unless args.empty?} (#{e.message})" }
      __copy_on_write__
      CowProxy.debug { "new target #{__getobj__.class.name} (#{__getobj__.object_id})" }
      __wrapped_value__(inst_var, method, *args, &block)
    end

    alias :_instance_variable_get :instance_variable_get
    alias :_instance_variable_set :instance_variable_set
    alias :_remove_instance_variable :remove_instance_variable
    alias :_instance_variable_defined? :instance_variable_defined?
    alias :_instance_variables :instance_variables
  end
end