require 'spec_helper'

RSpec.describe Transducers do
  include Transducers

  class Inc
    def xform(n)
      n + 1
    end
  end

  it "creates a mapping transducer" do
    transducer = mapping(Inc.new)
    actual = [1,2,3].transduce(transducer, :<<, [])
    expect(actual).to eq([2,3,4])
  end

  it "maps over an enumerator" do
    transducer = Transducers.mapping(Inc.new)
    reducer = Reducers.wrap(:<<)
    actual = 1.upto(3).transduce(transducer, reducer, [])
    expect(actual).to eq([2,3,4])
  end

  example do
    expect([1,2,3].transduce(Transducers.mapping(Inc.new), :+, 0)).to eq(9)
  end

  it "creates a filtering transducer" do
    transducer = Transducers.filtering(:even?)
    actual = [1,2,3,4,5].transduce(transducer, :<<, [])
    expect(actual).to eq([2,4])
  end

  it "composes transducers (or any fns, really)" do
    transducer = Transducers.compose(Transducers.mapping(Inc.new),
                                     Transducers.filtering(:even?))
    actual = 1.upto(3).transduce(transducer, :<<, [])
    expect(actual).to eq([2,4])
  end
end
