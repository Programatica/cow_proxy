module CowProxy
  # A mixin to add wrapper getter and copy-on-write for
  # indexable classes, such as Array and Hash, i.e. classes
  # with [] method
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
        wrap_value = __wrap__(value)
        @hash[index] = wrap_value if wrap_value
        wrap_value || value
      end
    end

    # Extends {CowProxy::Base#initialize}
    def initialize(*)
      super
      @hash = {}
    end

    protected
    # Copy wrapped values to duplicated wrapped object
    # @see CowProxy::Base#__copy_on_write__
    # @return duplicated wrapped object
    def __copy_on_write__(*)
      super.tap do
        if @hash
          @hash.each do |k, v|
            __getobj__[k] = v
          end
          @hash.clear
        end
      end
    end
  end
end
