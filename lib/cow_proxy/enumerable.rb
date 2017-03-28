module CowProxy
  # A mixin to add mutable methods for keep_if, delete_if, select! and reject!
  # to wrap block params with CowProxy
  module Enumerable
    # Invokes the given block passing in successive elements from self,
    # deleting elements for which the block returns a false value.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be kept
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def keep_if(&block)
      mutable_selector(:select, &block)
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
      mutable_selector!(:keep_if, &block)
    end

    # Deletes every element of self for which block evaluates to true.
    #
    # @yield [item] Gives each element in self to the block
    # @yieldparam item Wrapped item in self
    # @yieldreturn [Boolean] true if item must be deleted
    # @return [CowProxy::Array] self if block given
    # @return [Enumerator] if no block given
    def delete_if(&block)
      mutable_selector(:reject, &block)
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
      mutable_selector!(:delete_if, &block)
    end

    private
    def mutable_selector(method, &block)
      return send(method) unless block
      @delegate_dc_obj = send(method, &block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    def mutable_selector!(method, &block)
      return send(method) unless block
      size = __getobj__.size
      send(method, &block)
      self unless __getobj__.size == size
    end
  end
end
