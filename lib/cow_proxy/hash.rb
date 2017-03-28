module CowProxy
  # Wrapper class for Hash
  class Hash < WrapClass(::Hash)
    include Indexable
    include Enumerable

    # Calls block once for each key in hash, passing the key-value pair
    # as parameters.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def each
      return enum_for(:each) unless block_given?
      __getobj__.each_key do |k|
        yield [k, self[k]]
      end
    end
    alias each_pair each

    # Calls block once for each key in hash, passing the value as parameter.
    #
    # @yield [value] Gives each value in hash to the block
    # @yieldparam value Wrapped value
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def each_value
      return enum_for(:each) unless block_given?
      each { |_, v| yield v }
    end

    # Returns a new hash consisting of entries for which the block returns true.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must be included
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def select
      ::Hash[super]
    end

    # Returns a new hash consisting of entries for which the block returns false.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must not be included
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def reject
      ::Hash[super]
    end

    # Returns a new array populated with the wrapped values from hash.
    #
    # @return [Array] Wrapped values from hash
    def values
      map(&:last)
    end

    # Deletes every key-value pair from hash for which block evaluates to false.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must be kept
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def keep_if(&block)
      @delegate_dc_obj = select(&block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    # Deletes every key-value pair from hash for which block evaluates to false.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must be kept
    # @return [CowProxy::Hash] self if block given and changes were made
    # @return [nil] if block given and no changes were made
    # @return [Enumerator] if no block given
    def select!(&block)
      size = __getobj__.size
      keep_if(&block)
      self unless __getobj__.size == size
    end

    # Deletes every key-value pair from hsh for which block evaluates to true.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must be deleted
    # @return [CowProxy::Hash] self if block given
    # @return [Enumerator] if no block given
    def delete_if(&block)
      @delegate_dc_obj = reject(&block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    # Deletes every key-value pair from hsh for which block evaluates to true.
    #
    # @yield [pair] Gives each key-value pair in self to the block
    # @yieldparam pair Array of key and wrapped value
    # @yieldreturn [Boolean] true if item must be deleted
    # @return [CowProxy::Hash] self if block given and changes were made
    # @return [nil] if block given and no changes were made
    # @return [Enumerator] if no block given
    def reject!(&block)
      size = __getobj__.size
      delete_if(&block)
      self unless __getobj__.size == size
    end

    # Used for merging into another Hash
    # needs to return unwrapped Hash
    #
    # @return [Hash] wrapped object
    def to_hash
      __getobj__
    end
  end
end
