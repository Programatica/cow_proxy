require 'test_helper'

class Config
  attr_accessor :a, :b
  def initialize(a)
    self.a = a
  end

  def ==(other)
    a == other.a && b == other.b
  end
end

describe CowProxy do
  describe 'proxy class' do
    before do
      nested_class = Struct.new(:n, :o)
      @origin = Config.new(1)
      @origin.b = [
        nested_class.new('a', {classes: 'new link', size: '2x2'}),
        nested_class.new('b', {rows: 2})
      ]
      @var = @origin.dup.deep_freeze!
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @origin

      @proxy.a.must_equal @origin.a
      (@proxy.a + 1).must_equal @origin.a + 1
      @var.a.must_equal @origin.a

      @proxy.b.must_equal @origin.b
      (@proxy.b[1].o[:rows] + 1).must_equal @origin.b[1].o[:rows] + 1
      @var.b.must_equal @origin.b
    end

    it 'raises on assign' do
      err = lambda { @proxy.a = 2 }.must_raise RuntimeError
      err.message.must_match(/can't modify frozen/)
      @proxy.must_equal @origin
      @proxy.a.must_equal @origin.a
      @proxy.b.must_equal @origin.b
    end

    it 'copy on write on mutable methods on child' do
      @proxy.b << 2

      @proxy.a.must_equal @origin.a
      @proxy.b.wont_equal @origin.b
      @var.b.must_equal @origin.b

      @proxy.wont_equal @origin
      @var.must_equal @origin
    end

    it 'copy on write on mutable methods on child of child' do
      @proxy.b[1].o[:rows] += 1
      @proxy.b[1].o[:rows].must_equal @origin.b[1].o[:rows] + 1
      @proxy.b[1].n.must_equal @origin.b[1].n
      @var.b[1].o[:rows].must_equal @origin.b[1].o[:rows]
      @proxy.b[0].must_equal @origin.b[0]

      @proxy.b[0].o[:classes] << ' custom'
      @proxy.b[0].o[:classes].must_equal @origin.b[0].o[:classes] + ' custom'
      @proxy.b[0].o[:size].must_equal @origin.b[0].o[:size]
      @proxy.b[0].o.wont_equal @origin.b[0].o
      @var.b[0].must_equal @origin.b[0]
    end
  end
end

