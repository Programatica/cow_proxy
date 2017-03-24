module CowProxy
  class Array < WrapClass(::Array)
    include Indexable

    # Used for concatenating into another Array
    # needs to return unwrapped Array
    #
    # @return [Array] wrapped object
    def to_ary
      __getobj__
    end
  end

end
