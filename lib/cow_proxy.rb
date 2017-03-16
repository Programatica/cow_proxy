module CowProxy
  class << self
    @@wrapper_classes = {}

    # create new proxy class for klass, with copy on write
    # in other case CowProxy will wrap objects with class without copy on write
    #
    # module CowProxy
    #   module MyModule
    #     class MyClass < WrapClass(::MyModule::MyClass)
    #     end
    #   end
    # end
    def WrapClass(klass)
      _WrapClass(klass)
    end

    # register proxy to be used when another proxy returns a value of klass,
    # so it wraps with proxy_klass.
    #
    # called automatically when inheriting from class returned by WrapClass
    def register_proxy(klass, proxy_klass)
      puts "register proxy for #{klass} with #{proxy_klass} < #{proxy_klass.superclass}" if ENV['DEBUG'] && !@@wrapper_classes[klass]
      @@wrapper_classes[klass] ||= proxy_klass
    end

    # return a proxy wrapping obj, using registered class for obj's class
    # if no class is registered for obj, it uses default proxy without
    # copy on write
    def wrap(obj)
      wrapper_class(obj).new(obj)
    end

    # returns proxy wrapper class for obj, registered proxy or default proxy
    # without copy on write
    def wrapper_class(obj)
      # only classes with defined wrapper and Structs has COW enabled by default
      @@wrapper_classes[obj.class] || _WrapClass(obj.class, obj.class < Struct, true)
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

    private
    def _WrapClass(klass, cow = true, register = false)
      proxy_superclass = get_proxy_klass_for(klass.superclass) || Base
      Kernel.puts "create new proxy class for #{klass}#{" from #{proxy_superclass}" if proxy_superclass}" if ENV['DEBUG']
      proxy_klass = Class.new(proxy_superclass) do |k|
        k.wrapped_class = klass
      end
      register_proxy klass, proxy_klass if register
      methods = klass.instance_methods
      methods -= [:_copy_on_write, :===, :frozen?]
      methods -= proxy_superclass.wrapped_class.instance_methods if proxy_superclass.wrapped_class
      methods -= [:inspect] if ENV['DEBUG']

      proxy_klass.module_eval do
        methods.each do |method|
          define_method method, CowProxy.send(:wrapping_block, method, cow)
        end
      end
      proxy_klass.define_singleton_method :public_instance_methods do |all=true|
        super(all) - klass.protected_instance_methods
      end
      proxy_klass.define_singleton_method :protected_instance_methods do |all=true|
        super(all) | klass.protected_instance_methods
      end
      proxy_klass
    end

    def get_proxy_klass_for(klass)
      wrapper = nil
      klass.ancestors.each do |ancestor|
        wrapper = @@wrapper_classes[ancestor] and break
      end
      wrapper
    end
  end
end

require 'cow_proxy/base.rb'
require 'cow_proxy/container.rb'
require 'cow_proxy/array.rb'
require 'cow_proxy/hash.rb'
require 'cow_proxy/string.rb'
require 'cow_proxy/set.rb'
