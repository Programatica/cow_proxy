require 'test_helper'

describe CowProxy do
  describe 'proxy integers' do
    it 'doesnt wrap' do
      refute CowProxy::Base === CowProxy.wrap(1)
    end
  end

  describe 'proxy floats' do
    it 'doesnt wrap' do
      refute CowProxy::Base === CowProxy.wrap(1.0)
    end
  end

  describe 'proxy symbols' do
    it 'doesnt wrap' do
      refute CowProxy::Base === CowProxy.wrap(:symbol)
    end
  end

  describe 'proxy nil' do
    it 'doesnt wrap' do
      refute CowProxy::Base === CowProxy.wrap(nil)
    end
  end

  describe 'proxy boolean' do
    it 'doesnt wrap' do
      refute CowProxy::Base === CowProxy.wrap(true)
      refute CowProxy::Base === CowProxy.wrap(false)
    end
  end

  describe 'proxy struct with immutable objects' do
    before do
      @var = ::Struct.new(:int, :bool, :proc).new(1, true, proc{ 3 }).deep_freeze!
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

      assert_equal instance_exec(&@proxy.proc), 3
    end
  end
end
