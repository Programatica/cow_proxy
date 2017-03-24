require 'test_helper'

describe CowProxy do
  describe 'proxy array' do
    before do
      @origin = [1, true, 'var']
      @var = @origin.dup.deep_freeze!
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

    it 'allow to be used with concat' do
      [].concat @proxy
    end

    it 'copy on write on mutable methods on child' do
      @proxy.must_equal @origin

      @proxy[2] << 's'
      @proxy[2].must_equal @origin[2] + 's'
      @var[2].must_equal @origin[2]
      @proxy.wont_equal @origin
      @proxy.must_equal @origin[0..1] + [@origin[2] + 's', *@origin[3..-1]]
      @var.must_equal @origin
    end

    it 'copy on write on mutable methods on child and then assign' do
      @proxy.must_equal @origin

      @proxy[2] << 's'
      @proxy[2].must_equal @origin[2] + 's'
      @var[2].must_equal @origin[2]

      @proxy[2] = 'new'
      @proxy[2].must_equal 'new'
      @var[2].must_equal @origin[2]
    end

    it 'copy on write on assign' do
      @proxy[1] = 2
      @proxy[0] = false
      @proxy.must_equal [false, 2, *@origin[2..-1]]
      @var.must_equal @origin
    end

    it 'copy on write on operation and assign' do
      @proxy[0] += 2
      @proxy.must_equal [@origin[0] + 2, *@origin[1..-1]]
      @var.must_equal @origin
    end

    it 'copy on write on add' do
      @proxy << :last
      @proxy.size.must_equal @origin.size + 1
      @var.size.must_equal @origin.size
    end

    it 'copy on write on replace all' do
      @proxy.replace [0]
      @proxy.must_equal [0]
      @var.must_equal @origin
    end

    it 'copy on write on assign and then replace all' do
      @proxy[1] = 0
      @proxy[1].must_equal 0
      @proxy.must_equal [@origin[0], 0, *@origin[2..-1]]
      @var.must_equal @origin

      @proxy.replace [0]
      @proxy.must_equal [0]
      @proxy[1].must_be_nil
      @var.must_equal @origin
    end
  end
end
