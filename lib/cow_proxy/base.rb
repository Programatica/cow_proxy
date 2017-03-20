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
      def wrapping_block(mid, cow_allowed)
        lambda do |*args, &block|
          target = __getobj__
          inst_var = "@#{mid}" if mid.to_s =~ /^\w+$/
          return _instance_variable_get(inst_var) if inst_var && _instance_variable_defined?(inst_var)
          if mid.to_s =~ /^(\w+)=$/ && _instance_variable_defined?("@#{$1}")
            Kernel.puts "remove #{$1}" if ENV['DEBUG']
            _remove_instance_variable "@#{$1}"
          end

          cow = cow_allowed
          begin
            Kernel.puts "run on #{target.class.name} (#{target.object_id}) #{mid} #{args.inspect unless args.empty?}" if ENV['DEBUG']
            value = target.__send__(mid, *args, &block)
            if inst_var && args.empty? && block.nil?
              wrap_value = wrap(value, inst_var)
              _instance_variable_set(inst_var, wrap_value) if wrap_value
            end
            wrap_value || value
          rescue => e
            raise unless cow && e.message =~ /^can't modify frozen/
            Kernel.puts "copy on write to run #{mid} #{args.inspect unless args.empty?} (#{e.message})" if ENV['DEBUG']
            target = _copy_on_write
            Kernel.puts "new target #{target.class.name} (#{target.object_id})" if ENV['DEBUG']
            cow = false
            retry
          ensure
            # cleanup exception line for retry
            $@.delete_if {|t| /\A#{Regexp.quote(__FILE__)}:#{__LINE__-3}:/o =~ t} if $@
          end
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
    # @!visibility public
    # Replace wrapped object with a copy, so object can
    # be modified.
    #
    # @param [Boolean] parent Replace proxy object in parent with
    #   duplicated wrapped object, if this proxy was created from
    #   another CowProxy.
    # @return duplicated wrapped object
    def _copy_on_write(parent = true)
      Kernel.puts "copy on write on #{__getobj__.class.name}" if ENV['DEBUG']
      return @delegate_dc_obj if @dc_obj_duplicated
      @delegate_dc_obj = @delegate_dc_obj.dup.tap do |new_target|
        @dc_obj_duplicated = true
        if parent && @parent_proxy
          @parent_proxy.send :_copy_on_write, false
          if @parent_var
            parent_dc = @parent_proxy._instance_variable_get(:@delegate_dc_obj)
            method = @parent_var[1..-1] + '='
            parent_dc.send(method, new_target)
          end
        end
      end
    end

    private
    def __getobj__  # :nodoc:
      @delegate_dc_obj
    end

    def wrap(value, inst_var = nil)
      if value.frozen?
        Kernel.puts "wrap #{value.class.name} with parent #{self.class.name}" if ENV['DEBUG']
        CowProxy.wrapper_class(value).new(value, self, inst_var)
      end
    end

    alias :_instance_variable_get :instance_variable_get
    alias :_instance_variable_set :instance_variable_set
    alias :_remove_instance_variable :remove_instance_variable
    alias :_instance_variable_defined? :instance_variable_defined?
    alias :_instance_variables? :instance_variable_defined?
  end
end