# This module include public api for CowProxy usage
#
# @example Create a CowProxy class and register to be used by wrap
#   module CowProxy
#     class CustomClass < WrapClass(::CustomClass)
#     end
#   end
#
# @example Call CowProxy.wrap with object to be proxied
#   obj = CustomClass.new
#   obj.freeze
#   proxy = CowProxy.wrap(obj)

module CowProxy
  class << self
    # @!visibility private
    @@wrapper_classes = {}

    # Create new proxy class for klass, with copy on write enabled.
    #
    # In other case CowProxy will wrap objects of klass without copy on write
    #
    #   module CowProxy
    #     module MyModule
    #       class MyClass < WrapClass(::MyModule::MyClass)
    #       end
    #     end
    #   end
    #
    # @return new proxy class, so it can be used to create a class which inherits from it
    def WrapClass(klass)
      _WrapClass(klass)
    end

    # Register proxy to be used when wrapping an object of klass.
    #
    # It's called automatically when inheriting from class returned by WrapClass
    # Can be called with nil proxy_klass to disable wrapping objects of klass, for
    # example Integer is registered with nil because there is no point in wrapping
    # immutable classes.
    #
    # @return proxy_klass
    def register_proxy(klass, proxy_klass)
      debug { "register proxy for #{klass} with #{proxy_klass}#{" < #{proxy_klass.superclass}" if proxy_klass}" } unless @@wrapper_classes[klass]
      @@wrapper_classes[klass] ||= proxy_klass
    end

    # Returns a proxy wrapping obj, using registered class for obj's class.
    # If no class is registered for obj's class, it uses default proxy, without
    # copy on write.
    #
    # If class is registered with nil Proxy, return obj.
    #
    # @return wrapped obj with CowProxy class
    def wrap(obj)
      klass = wrapper_class(obj)
      klass ? klass.new(obj) : obj
    end

    # Returns proxy wrapper class for obj.
    # It will return registered proxy or default proxy without copy on write
    # if none is registered.
    #
    # @return registered proxy or default proxy without copy on write
    #   if none is registered
    def wrapper_class(obj)
      # only classes with defined wrapper and Structs has COW enabled by default
      if @@wrapper_classes.has_key?(obj.class)
        @@wrapper_classes[obj.class]
      else
        _WrapClass(obj.class, obj.class < Struct, true)
      end
    end

    # Print debug line if debug is enabled (ENV['DEBUG'] true)
    # Accepts a block instead of line, so interpolation is skipped
    # when debug is disabled
    #
    # @param [String] line debug line to print
    # @return nil
    def debug(line = nil)
      return unless ENV['DEBUG']
      line ||= yield if block_given?
      Kernel.puts line
    end

    private
    def _WrapClass(klass, cow = true, register = false)
      proxy_superclass = get_proxy_klass_for(klass.superclass) || Base
      debug { "create new proxy class for #{klass}#{" from #{proxy_superclass}" if proxy_superclass}" }
      proxy_klass = Class.new(proxy_superclass) do |k|
        k.wrapped_class = klass
      end
      register_proxy klass, proxy_klass if register
      methods = klass.instance_methods
      methods -= [:__copy_on_write__, :__wrap__, :__wrapped_value__, :__wrapped_method__, :__getobj__, :enum_for, :send, :===, :frozen?]
      methods -= proxy_superclass.wrapped_class.instance_methods if proxy_superclass.wrapped_class
      methods -= [:inspect] if ENV['DEBUG']

      proxy_klass.module_eval do
        methods.each do |method|
          define_method method, proxy_klass.wrapping_block(method, cow)
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

# no proxy klass for immutable classes
[Integer, Float, Symbol, TrueClass, FalseClass, NilClass].each do |klass|
  CowProxy.register_proxy klass, nil
end
if defined? Fixnum
  CowProxy.register_proxy Fixnum, nil
end
if defined? Bignum
  CowProxy.register_proxy Bignum, nil
end

require 'cow_proxy/base.rb'
require 'cow_proxy/indexable.rb'
require 'cow_proxy/array.rb'
require 'cow_proxy/hash.rb'
require 'cow_proxy/string.rb'
require 'cow_proxy/set.rb'
