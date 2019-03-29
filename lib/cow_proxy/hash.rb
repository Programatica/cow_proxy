module CowProxy
  # Wrapper class for Hash
  class Hash < WrapClass(::Hash)
    include Indexable
    include ::Enumerable
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

    # Returns true if the given key is present in hash.
    #
    # @return [Array] Wrapped values from hash
    def include?(key)
      key?(key)
    end

    # Used for merging into another Hash
    # needs to return unwrapped Hash
    #
    # @return [Hash] wrapped object
    def to_hash
      __getobj__
    end

    # Compute a hash-code for this hash. Two hashes with the same content
    # will have the same hash code (and will compare using eql?).
    #
    # @return [Intenger] calculated hash code
    def hash
      __getobj__.hash
    end
  end
end
