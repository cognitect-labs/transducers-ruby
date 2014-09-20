require 'spec_helper'

RSpec.describe Transducers do
  describe "mapping" do
    example do
      inc = ->(n){n+1}
      mapping_inc = Transducers.mapping(inc)
      append = ->(a,i){a << i}
      actual = [1,2,3].transduce(mapping_inc, append, [])
      expect(actual).to eq([2,3,4])
    end
  end

  describe "filtering" do
    example do
      even = ->(n){n.even?}
      filtering_evens = Transducers.filtering(even)
      append = ->(a,i){a << i}
      actual = [1,2,3,4,5].transduce(filtering_evens, append, [])
      expect(actual).to eq([2,4])
    end
  end

  describe "composing" do
    example do
      inc = ->(n){n+1}
      mapping_inc = Transducers.mapping(inc)
      even = ->(n){n.even?}
      filtering_evens = Transducers.filtering(even)
      append = ->(a,i){a << i}
      xform = Transducers.compose(mapping_inc, filtering_evens)
      actual = [1,2,3,4,5].transduce(xform, append, [])
      expect(actual).to eq([2,4,6])
    end
  end
end
