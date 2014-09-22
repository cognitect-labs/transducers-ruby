require 'spec_helper'

RSpec.describe Transducers do
  let(:inc)    { ->(n){n + 1} }
  let(:even)   { ->(n){n.even?} }
  let(:append) { ->(a,i){a << i} }

  it "creates a mapping transducer" do
    mapping_inc = Transducers.mapping(inc)
    actual = [1,2,3].transduce(mapping_inc, append, [])
    expect(actual).to eq([2,3,4])
  end

  it "maps over an enumerator" do
    mapping_inc = Transducers.mapping(inc)
    actual = 1.upto(3).transduce(mapping_inc, append, [])
    expect(actual).to eq([2,3,4])
  end

  it "creates a filtering transducer" do
    filtering_evens = Transducers.filtering(even)
    actual = [1,2,3,4,5].transduce(filtering_evens, append, [])
    expect(actual).to eq([2,4])
  end

  it "creates a taking transducer" do
    taking_3 = Transducers.taking(3)
    actual = [1,2,3,4,5].transduce(taking_3, append, [])
    expect(actual).to eq([1,2,3])
  end

  it "composes transducers (or any fns, really)" do
    transducer = Transducers.compose(Transducers.mapping(inc),
                                     Transducers.filtering(even),
                                     Transducers.taking(6))
    actual = 1.upto(20).transduce(transducer, append, [])
    expect(actual).to eq([2,4,6,8,10,12])
  end
end
