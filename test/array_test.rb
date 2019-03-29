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
      @proxy.dig(0).must_equal @origin[0]
      (@proxy[0] + 1).must_equal @origin[0] + 1
      @var[0].must_equal @origin[0]

      @proxy[1].must_equal @origin[1]
      @proxy.dig(1).must_equal @origin[1]
      (!@proxy[1]).must_equal !@origin[1]
      @var[1].must_equal @origin[1]

      @proxy[2].must_equal @origin[2]
      @proxy.dig(2).must_equal @origin[2]
      (@proxy[2] + 's').must_equal @origin[2] + 's'
      @var[2].must_equal @origin[2]

      assert @proxy.include?('var')
      assert @proxy.include?(1)
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
      @proxy.dig(2).must_equal @origin[2] + 's'
      @var[2].must_equal @origin[2]
      refute @proxy.include?(@var[2])
      assert @proxy.include?(@var[2] + 's')

      @proxy[2] = 'new'
      @proxy[2].must_equal 'new'
      @proxy.dig(2).must_equal 'new'
      @var[2].must_equal @origin[2]
      refute @proxy.include?(@var[2])
      assert @proxy.include?('new')
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

    it 'change child on each with mutable method' do
      @proxy.each { |item| item.upcase! if item.is_a? String }
      @proxy.wont_equal @origin
      @var.must_equal @origin
      @proxy[2].must_equal @origin[2].upcase
    end

    it 'change child on each.with_index with mutable method' do
      @proxy.each.with_index { |item| item.upcase! if item.is_a? String }
      @proxy.wont_equal @origin
      @var.must_equal @origin
      @proxy[2].must_equal @origin[2].upcase
    end

    it 'change child on map with mutable method' do
      result = @proxy.map { |item| item.is_a?(Integer) ? item + 1 : item }
      @proxy.must_equal @origin
      @var.must_equal @origin
      result.wont_equal @origin
      result[0].must_equal @origin[0] + 1
      result[2].upcase!.must_equal @origin[2].upcase
    end

    it 'change child on select and each with mutable method' do
      result = @proxy.select { |item| item.is_a? String }.each(&:upcase!)
      @var.must_equal @origin
      @proxy.wont_equal @origin
      result.must_equal [@origin[2].upcase]
    end

    it 'change child on select! and each with mutable method' do
      @proxy[2] << 's'
      refute_nil @proxy.select! { |item| item << 's' if item.is_a? String }
      @proxy.each(&:upcase!)
      @var.must_equal @origin
      @proxy.wont_equal @origin
      @proxy.must_equal [(@origin[2] + 'ss').upcase]
    end

    it 'returns nil when select! with true' do
      assert_nil @proxy.select! { |_| true }
      @proxy.must_equal @origin
    end

    it 'change child on keep_if and each with mutable method' do
      @proxy.keep_if { |item| item << 's' if item.is_a? String }
      @proxy.each(&:upcase!)
      @var.must_equal @origin
      @proxy.wont_equal @origin
      @proxy.must_equal [(@origin[2] + 's').upcase]
    end

    it 'change child on reject! and each with mutable method' do
      result = @proxy.reject! do |item|
        if item.is_a? String
          item << 's'
          false
        else
          true
        end
      end
      refute_nil result
      @proxy.each(&:upcase!)
      @var.must_equal @origin
      @proxy.wont_equal @origin
      @proxy.must_equal [(@origin[2] + 's').upcase]
    end

    it 'returns nil when reject! with false' do
      assert_nil @proxy.reject! { |_| false }
      @proxy.must_equal @origin
    end

    it 'change child on delete_if and each with mutable method' do
      @proxy.delete_if do |item|
        if item.is_a? String
          item << 's'
          false
        else
          true
        end
      end
      @proxy.each(&:upcase!)
      @var.must_equal @origin
      @proxy.wont_equal @origin
      @proxy.must_equal [(@origin[2] + 's').upcase]
    end

    it 'change child on map! with mutable method' do
      @proxy.map! { |item| item.is_a?(String) ? item.upcase! : item }
      @var.must_equal @origin
      @proxy.wont_equal @origin
      @proxy[2].must_equal @origin[2].upcase
    end

    it 'grep return wrapped string' do
      @proxy.grep(String).must_equal ['var']
    end

    it 'allow union with other array' do
      ([1, false] | @proxy).must_equal([1, false] | @origin)
    end
  end
end
