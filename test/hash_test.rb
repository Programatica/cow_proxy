require 'test_helper'

describe CowProxy do
  describe 'proxy hash' do
    before do
      @origin = {a: 1, b: true, c: 'var'}
      @var = @origin.dup.deep_freeze!
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @var
      @proxy.size.must_equal @var.size

      @proxy[:a].must_equal @origin[:a]
      (@proxy[:a] + 1).must_equal @origin[:a] + 1
      @var[:a].must_equal @origin[:a]

      @proxy[:b].must_equal @origin[:b]
      (!@proxy[:b]).must_equal !@origin[:b]
      @var[:b].must_equal @origin[:b]

      @proxy[:c].must_equal @origin[:c]
      (@proxy[:c] + 's').must_equal @origin[:c] + 's'
      @var[:c].must_equal @origin[:c]
    end

    it 'copy on write on mutable methods on child' do
      @proxy.must_equal @var

      @proxy[:c] << 's'
      @proxy[:c].must_equal @origin[:c] + 's'
      @var[:c].must_equal @origin[:c]
      @proxy.must_equal @origin.merge(c: @origin[:c] + 's')
      @var.must_equal @origin
    end

    it 'copy on write on mutable methods on child and then assign' do
      @proxy.must_equal @origin

      @proxy[:c] << 's'
      @proxy[:c].must_equal @origin[:c] + 's'
      @var[:c].must_equal @origin[:c]

      @proxy[:c] = 'new'
      @proxy[:c].must_equal 'new'
      @var[:c].must_equal @origin[:c]
    end

    it 'copy on write on assign' do
      @proxy[:b] = 2
      @proxy[:a] = false
      @proxy.must_equal @origin.merge(b: 2, a: false)
      @var.must_equal @origin
    end

    it 'copy on write on operation and assign' do
      @proxy[:a] += 2
      @proxy.must_equal @origin.merge(a: @origin[:a] + 2)
      @var.must_equal @origin
    end

    it 'copy on write on add' do
      @proxy.update d: 'last'
      @proxy.size.must_equal @origin.size + 1
      @var.size.must_equal @origin.size
    end

    it 'copy on write on replace' do
      @proxy.update c: 'last'
      @proxy[:c].must_equal 'last'
      @var[:c].must_equal @origin[:c]
    end

    it 'copy on write on mutable methods on child and then add' do
      @proxy.must_equal @origin

      @proxy[:c] << 's'
      @proxy[:c].must_equal @origin[:c] + 's'
      @var[:c].must_equal @origin[:c]

      @proxy.update d: 'last'
      @proxy[:c].must_equal @origin[:c] + 's'
      @proxy.size.must_equal @origin.size + 1
      @var.size.must_equal @origin.size
    end

    it 'copy on write on mutable methods on child and then replace' do
      @proxy.must_equal @origin

      @proxy[:c] << 's'
      @proxy[:c].must_equal @origin[:c] + 's'
      @var[:c].must_equal @origin[:c]

      @proxy.update b: 'last'
      @proxy[:c].must_equal @origin[:c] + 's'
      @proxy[:b].must_equal 'last'
      @var[:b].must_equal @origin[:b]
    end
  end
end
