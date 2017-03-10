require 'test_helper'

describe CowProxy do
  describe 'proxy integers' do
    before do
      @var = 1
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @var
      (@proxy + 1).must_equal 2
      @var.must_equal 1
    end
  end

  describe 'proxy boolean' do
    before do
      @var = true
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @var
      (!@proxy).must_equal false
      @var.must_equal true
    end
  end

  describe 'proxy struct with unmutable objects' do
    before do
      @var = Struct.new(:int, :bool).new(1, true).freeze
      @proxy = CowProxy.wrap(@var)
    end

    it 'delegates methods' do
      @proxy.must_equal @var

      @proxy.int.must_equal 1
      (@proxy.int + 1).must_equal 2
      @proxy.int += 1
      @proxy.int.must_equal 2
      @var.int.must_equal 1

      @proxy.bool.must_equal true
      (!@proxy.bool).must_equal false
      @proxy.bool = false
      @proxy.bool.must_equal false
      @var.bool.must_equal true
    end
  end
end
