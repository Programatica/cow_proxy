module CowProxy
  class Hash < WrapClass(::Hash)
    include Indexable

    # Used for merging into another Hash
    # needs to return unwrapped Hash
    #
    # @return [Hash] wrapped object
    def to_hash
      __getobj__
    end
  end

end
