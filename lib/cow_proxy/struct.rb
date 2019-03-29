module CowProxy
  # Wrapper class for Struct
  class Struct < WrapClass(::Struct)
    # Extracts the nested value specified by the sequence of idx objects by
    # calling dig at each step, returning nil if any intermediate step is nil.
    #
    # @return CowProxy wrapped value from wrapped object
    def dig(key, *args)
      value = send(key)
      args.empty? ? value : value&.dig(*args)
    end
  end
end
