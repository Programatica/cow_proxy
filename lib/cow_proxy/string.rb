module CowProxy
  # Wrapper class for String
  class String < WrapClass(::String)
    # returns the wrapped object.
    #
    # needed to used wrapped string as parameter for send
    #
    # @return the wrapped object.
    def to_str
      __getobj__
    end
  end
end