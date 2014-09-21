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

  it "composes transducers (or any fns, really)" do
    mapping_inc = Transducers.mapping(inc)
    filtering_evens = Transducers.filtering(even)
    xform = Transducers.compose(mapping_inc, filtering_evens)
    actual = [1,2,3,4,5].transduce(xform, append, [])
    expect(actual).to eq([2,4,6])
  end
end
