module CowProxy
  class Array < WrapClass(::Array)
    include Container
  end

end
