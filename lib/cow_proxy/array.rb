module CowProxy
  class Array < WrapClass(::Array)
    include Indexable
    include Enumerable

    # Calls the given block once for each element in self,
    # passing wrapped element as a parameter.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def each(&block)
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
    def map!(&block)
      __copy_on_write__
      return enum_for(:map!) unless block_given?
      __getobj__.each.with_index do |item, i|
        self[i] = yield(self[i])
      end
    end
    alias collect! map!

    # Invokes the given block passing in successive elements from self,
    # deleting elements for which the block returns a false value.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be kept
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def keep_if(&block)
      @delegate_dc_obj = select(&block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    # Invokes the given block passing in successive elements from self,
    # deleting elements for which the block returns a false value.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be kept
    # @return [CowProxy::Array] self if block given and changes were made
    # @return [nil] if block given and no changes were made
    # @return [Enumerator] if no block given
    def select!(&block)
      size = __getobj__.size
      keep_if &block
      self unless __getobj__.size == size
    end

    # Deletes every element of self for which block evaluates to true.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be deleted
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def delete_if(&block)
      @delegate_dc_obj = reject(&block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    # Deletes every element of self for which block evaluates to true.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be deleted
    # @return [CowProxy::Array] self if block given and changes were made
    # @return [nil] if block given and no changes were made
    # @return [Enumerator] if no block given
    def reject!(&block)
      size = __getobj__.size
      delete_if &block
      self unless __getobj__.size == size
    end

    # Used for concatenating into another Array
    # needs to return unwrapped Array
    #
    # @return [Array] wrapped object
    def to_ary
      __getobj__
    end
  end

end
