require 'test_helper'

describe CowProxy do
  describe 'proxy set' do
    before do
      @origin = Set.new [1, true, 'var']
      @var = @origin.dup.deep_freeze!
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @origin
      @proxy.size.must_equal @origin.size

      @proxy.include?(1).must_equal @origin.include?(1)
      @proxy.include?(0).must_equal @origin.include?(0)
    end

    it 'copy on write on add' do
      @proxy << :last
      @proxy.size.must_equal @origin.size + 1
      @var.size.must_equal @origin.size
    end
  end
end
