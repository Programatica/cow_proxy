module CowProxy
  module Indexable
    # Calls [](index) in wrapped object and keep wrapped
    # value, so same wrapped value is return on following
    # calls with same index.
    #
    # @return CowProxy wrapped value from wrapped object
    def [](index)
      return @hash[index] if @hash && @hash.has_key?(index)

      begin
        value = __getobj__[index]
        return value if @hash.nil?
        wrap_value = wrap(value)
        @hash[index] = wrap_value if wrap_value
        wrap_value || value
      end
    end

    def initialize(*)
      super
      @hash = {}
    end

    def _copy_on_write(*)
      super.tap do
        if @hash
          @hash.each do |k, v|
            __getobj__[k] = v
          end
          @hash = nil
        end
      end
    end
  end
end
