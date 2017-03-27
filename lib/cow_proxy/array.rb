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

    def map!(&block)
      __copy_on_write__
      return enum_for(:map!) unless block_given?
      change = false
      __getobj__.each.with_index do |item, i|
        self[i] = yield(self[i]).tap do |result|
          change ||= item != result
        end
      end
      self if change
    end

    def keep_if(&block)
      @delegate_dc_obj = select(&block).tap do
        @dc_obj_duplicated = true
      end
      self
    end

    def select!(&block)
      size = __getobj__.size
      keep_if &block
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
