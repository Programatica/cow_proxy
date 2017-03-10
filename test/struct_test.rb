require 'test_helper'

describe CowProxy do
  describe 'proxy struct' do
    before do
      @origin = Struct.new(:a, :b, :c, :d).new(1, true, 'var', 'test')
      @var = @origin.dup.deep_freeze!
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @origin
      @proxy.to_a.size.must_equal @origin.to_a.size

      @proxy.a.must_equal @origin.a
      (@proxy.a + 1).must_equal @origin.a + 1
      @var.a.must_equal @origin.a

      @proxy.b.must_equal @origin.b
      (!@proxy.b).must_equal !@origin.b
      @var.b.must_equal @origin.b

      @proxy.c.must_equal @origin.c
      (@proxy.c + 's').must_equal @origin.c + 's'
      @var.c.must_equal @origin.c
    end

    it 'copy on write on mutable methods on child' do
      @proxy.must_equal @origin

      @proxy.c << 's'
      @proxy.c.must_equal @origin.c + 's'
      @var.c.must_equal @origin.c

      @proxy.wont_equal @origin
      @var.must_equal @origin

      @proxy.d << 's'
      @proxy.d.must_equal @origin.d + 's'
      @proxy.c.must_equal @origin.c + 's'
      @var.d.must_equal @origin.d
    end

    it 'copy on write on assign' do
      @proxy.b = 2
      @proxy.a = false
      @proxy.to_a.must_equal [false, 2, *@origin.to_a[2..-1]]
      @var.to_a.must_equal @origin.to_a
    end

    it 'copy on write on mutable methods on child and then assign' do
      @proxy.must_equal @origin

      @proxy.c << 's'
      @proxy.c.must_equal @origin.c + 's'
      @var.c.must_equal @origin.c

      @proxy.c = 'new'
      @proxy.c.must_equal 'new'
      @var.c.must_equal @origin.c
    end
  end
end
