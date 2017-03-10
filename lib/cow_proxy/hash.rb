module CowProxy
  class Hash < WrapClass(::Hash)
    include Container
  end

end
