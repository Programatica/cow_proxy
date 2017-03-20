module CowProxy
  class Hash < WrapClass(::Hash)
    include Indexable
  end

end
