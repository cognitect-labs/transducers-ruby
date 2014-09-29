require 'spec_helper'

RSpec.describe Transducers::Reducer do
  Reducer = Transducers::Reducer

  example do
    r = Reducer.new(0, :+)
    expect(r.init).to eq(0)
    expect(r.result(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end

  example do
    r = Reducer.new(0) {|r,i| r+i}
    expect(r.init).to eq(0)
    expect(r.result(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end

  example do
    init = Class.new do
      attr_reader :val
      def initialize
        @val = []
      end

      def foo(v)
        @val << v
        self
      end
    end.new
    result = Transducers.transduce(Transducers.mapping {|n|n+1}, :foo, init, [1,2,3])
    expect(result.val).to eq([2,3,4])
  end
end
