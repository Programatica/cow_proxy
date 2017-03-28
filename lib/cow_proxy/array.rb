module CowProxy
  # Wrapper class for Array
  class Array < WrapClass(::Array)
    include Indexable
    include ::Enumerable
    include Enumerable

    # Calls the given block once for each element in self,
    # passing wrapped element as a parameter.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def each
      return enum_for(:each) unless block_given?
      __getobj__.each.with_index do |_, i|
        yield self[i]
      end
      self
    end

    # Invokes the given block once for each element of self,
    # replacing the element with the value returned by the block.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn item to replace
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def map!
      __copy_on_write__
      return enum_for(:map!) unless block_given?
      __getobj__.each.with_index do |_, i|
        self[i] = yield(self[i])
      end
    end
    alias collect! map!

    # Used for concatenating into another Array
    # needs to return unwrapped Array
    #
    # @return [Array] wrapped object
    def to_ary
      __getobj__
    end
  end
end
