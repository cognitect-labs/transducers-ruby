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
    reducer = Transducers.wrap(:<<)
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

  it "creates a taking transducer" do
    transducer = Transducers.taking(5)
    actual = 1.upto(20).transduce(transducer, :<<, [])
    expect(actual).to eq([1,2,3,4,5])
  end

  it "creates a catting transducer" do
    expect([[1,2],[3,4]].transduce(Transducers.cat, :<<, [])).to eq([1,2,3,4])
  end

  example do
    td = Transducers.compose(Transducers.taking(5),
                             Transducers.mapping(Inc.new),
                             Transducers.filtering(:even?))
    expect((1..20).transduce(td, :+, 0)).to eq(12)
  end

  example do
    sum = Class.new do
      def xform(a)
        [a.reduce(&:+)]
      end
    end.new

    actual = [[1,2],[3,4]].transduce(Transducers.compose(Transducers.mapping(sum),
                                                         Transducers.cat),
                                     :<<,
                                     [])
    expect(actual).to eq([3,7])
  end

  it "composes transducers (or any fns, really)" do
    transducer = Transducers.compose(Transducers.mapping(Inc.new),
                                     Transducers.filtering(:even?))
    actual = 1.upto(3).transduce(transducer, :<<, [])
    expect(actual).to eq([2,4])
  end
end
