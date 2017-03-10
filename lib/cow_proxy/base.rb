module CowProxy
  class Base
    class << self
      attr_accessor :wrapped_class

      def inherited(subclass)
        subclass.wrapped_class = wrapped_class
        CowProxy.register_proxy wrapped_class, subclass if wrapped_class
      end
    end

    def initialize(obj, parent = nil, parent_var = nil)
      @delegate_dc_obj = obj
      @parent_proxy = parent
      @parent_var = parent_var
    end

    def _copy_on_write(parent = true)
      Kernel.puts "copy on write on #{self.class.name}" if ENV['DEBUG']
      @delegate_dc_obj = @delegate_dc_obj.dup.tap do |new_target|
        if parent && @parent_proxy
          @parent_proxy._copy_on_write(false)
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
        #@parent_proxy._copy_on_write(false) if @parent_proxy
        CowProxy.wrap(value, self, inst_var)
      end
    end

    alias :_instance_variable_get :instance_variable_get
    alias :_instance_variable_set :instance_variable_set
    alias :_remove_instance_variable :remove_instance_variable
    alias :_instance_variable_defined? :instance_variable_defined?
    alias :_instance_variables? :instance_variable_defined?
  end
end