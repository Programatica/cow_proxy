module CowProxy
  class Array < WrapClass(::Array)
    include Indexable
  end

end
