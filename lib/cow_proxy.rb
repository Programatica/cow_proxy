module CowProxy
  @@wrapper_classes = {}

  def self.get_wrapper_class(klass)
    wrapper = nil
    klass.ancestors.each do |ancestor|
      wrapper = @@wrapper_classes[ancestor] and break
    end
    wrapper
  end

  def self.wrapper_class(obj)
    return const_get(obj.class.name) if obj.class.name && const_defined?(obj.class.name, false)
    # only classes with defined wrapper and Structs has COW enabled by default
    get_wrapper_class(obj.class) || CowProxy::WrapClass(obj.class, obj.class < Struct)
  end

  def self.wrap(obj, parent = nil, parent_var = nil)
    Kernel.puts "wrap #{obj.class.name} with parent #{parent.class.name}" if parent && ENV['DEBUG']
    wrapper_class(obj).new(obj, parent, parent_var)
  end

  def self.WrapClass(superclass, cow = true)
    @@wrapper_classes[superclass] = klass = Class.new(Base)
    methods = superclass.instance_methods
    methods -= [:_copy_on_write, :===, :frozen?]
    #methods -= [:inspect] if ENV['DEBUG']

    klass.module_eval do
      methods.each do |method|
        if false && method.to_s =~ /\w+=$/
          attr_writer method.to_s[0..-2]
        else
          define_method method, CowProxy.wrapping_block(method, cow)
        end
      end
    end
    klass.define_singleton_method :public_instance_methods do |all=true|
      super(all) - superclass.protected_instance_methods
    end
    klass.define_singleton_method :protected_instance_methods do |all=true|
      super(all) | superclass.protected_instance_methods
    end
    klass
  end

  def self.wrapping_block(mid, cow_allowed)
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
        Kernel.puts '-----' if ENV['DEBUG']
        # cleanup exception from cow proxy files
        $@.delete_if {|t| /\A#{Regexp.quote(__FILE__)}:#{__LINE__-2}:/o =~ t} if $@
      end
    end
  end
end

require 'cow_proxy/base.rb'
require 'cow_proxy/container.rb'
require 'cow_proxy/array.rb'
require 'cow_proxy/hash.rb'
require 'cow_proxy/string.rb'
