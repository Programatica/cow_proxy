require 'test_helper'

describe CowProxy do
  describe 'proxy array' do
    before do
      @origin = [1, true, 'var', [2]]
      @var = @origin[0..1] + @origin[2..-1].map(&:dup)
      @var[-1].freeze
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @origin
      @proxy.size.must_equal @origin.size

      @proxy[0].must_equal @origin[0]
      (@proxy[0] + 1).must_equal @origin[0] + 1
      @var[0].must_equal @origin[0]

      @proxy[1].must_equal @origin[1]
      (!@proxy[1]).must_equal !@origin[1]
      @var[1].must_equal @origin[1]

      @proxy[2].must_equal @origin[2]
      (@proxy[2] + 's').must_equal @origin[2] + 's'
      @var[2].must_equal @origin[2]
    end

    it 'change child on mutable methods on child' do
      @proxy.must_equal @origin
      @var.must_equal @origin

      @proxy[2] << 's'
      @proxy[2].must_equal @origin[2] + 's'
      @proxy.wont_equal @origin
      @var.wont_equal @origin
    end

    it 'copy on write on assign' do
      @proxy[-1][0] = 0
      @proxy[-1][1] = false
      @proxy.must_equal [*@origin[0..-2], [0, false]]
      @var.must_equal @origin
    end

    it 'copy on write on replace all' do
      @proxy[-1].replace [0]
      @proxy[-1].must_equal [0]
      @var.must_equal @origin
      @proxy.wont_equal @origin
    end
  end
end
