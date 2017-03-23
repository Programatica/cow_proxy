module CowProxy
  class String < WrapClass(::String)
    def to_str
      __getobj__.to_str
    end
  end
end