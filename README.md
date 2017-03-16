Overview
========

This is a copy-on-write proxy for frozen Ruby objects, so duplicating frozen object is delayed until a method tries to change frozen object.

CowProxy classes for array, hash, string and struct are provided. Objects from other classes will be proxied without copy-on-write, you have to create a CowProxy class for them. Also you have to create CowProxy class for each object which have any getter method with arguments, because default CowProxy won't wrap returned value. Immutable classes such as Integer or TrueClass doesn't need copy-on-write proxy because they can't be changed.

You can wrap every object in a proxy. Proxy will always send method calls to wrapped object, and wrap returned value with CowProxy if method had no argument, so a proxy will always return proxy objects for getters without arguments. When a method tries to change a frozen object, if proxy has copy-on-write enabled, it will duplicate frozen object and will send next method calls to duplicated object, in other case an exception is raised.

Usage
-----

Call CowProxy.wrap with object to be proxied:

```ruby
CowProxy.wrap(obj)
```

It doesn't need to be a frozen object, it can be frozen later or only have references to frozen objects, but no object will be duplicated until some change is requested on frozen object.

To create a CowProxy class for custom class, create a new class which inherits from CowProxy::WrapClass(CustomClass):

```ruby
module YourModule
  class CustomProxy < CowProxy::WrapClass(CustomClass)
  end
end
  
obj = CustomClass.new(...)
obj.freeze
proxy = CowProxy.wrap(obj)
```

You can create proxy in CowProxy module too:

```ruby
module CowProxy
  class CustomClass < WrapClass(::CustomClass)
  end
end
```

If your custom class has some getters with arguments, such as [] method of Array or Hash, you will have to define it in your Proxy so it wraps returned values and memoizes them, and override _copy_on_write to set memoized proxies to duplicated object. Wrapped object can be accessed from proxy with \__getobj\__ method. You can see an example in CowProxy::Container module, which is used for Array and Hash classes.
 
If your custom class inherits from a class with CowProxy class, you don't need to create an own class, unless you need to override some method:
 
 ```ruby
module CowProxy
  class CustomClass < Array
    def custom_get(arg)
      return @custom_var[index] if @custom_var && @custom_var.has_key?(arg)

      begin
        value = __getobj__.custom_get(arg)
        return value if @custom_var.nil?
        wrap_value = wrap(value)
        @custom_var[index] = wrap_value if wrap_value
        wrap_value || value
      ensure
        $@.delete_if {|t| /\A#{Regexp.quote(__FILE__)}:#{__LINE__-2}:/o =~ t} if $@
      end
    end

    def initialize(obj, *)
      super
      @custom_var = {}
    end

    def _copy_on_write(*)
      super.tap do
        if @custom_var
          @custom_var.each do |k, v|
            __getobj__.custom_set(k, v)
          end
          @custom_var = nil
        end
      end
    end
  end
end
```
