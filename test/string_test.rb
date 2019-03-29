require 'test_helper'

describe CowProxy do
  describe 'proxy string' do
    before do
      @origin = 'size'
      @var = @origin.dup.freeze
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @origin
      (@proxy + 's').must_equal @origin + 's'
      @proxy.must_equal @origin
      @var.must_equal @origin
      @proxy.size.must_equal @origin.size
    end

    it 'copy on write on mutable methods' do
      @proxy.must_equal @origin
      @proxy << 's'
      @proxy.must_equal @origin + 's'
      @var.must_equal @origin

      @proxy.size.must_equal @origin.size + 1
      @var.size.must_equal @origin.size
    end
    
    it 'allow to use in interpolation' do
      "#{@proxy}".must_equal @origin
    end

    it 'allow to use in interpolation after being mutated' do
      @proxy << 's'
      "#{@proxy}".must_equal @origin + 's'
    end
    
    it 'allow to send with wrapped string' do
      @origin.send(@proxy).must_equal 4
    end

    it 'is string for case equality' do
      assert String === @proxy
    end
  end
end
