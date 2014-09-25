require 'spec_helper'

RSpec.describe Transducers do
  include Transducers

  it "creates a mapping transducer with an object" do
    inc = Class.new do
      def xform(n) n + 1 end
    end.new
    actual = [1,2,3].transduce(mapping(inc), :<<, [])
    expect(actual).to eq([2,3,4])
  end

  it "creates a mapping transducer with a block" do
    actual = [1,2,3].transduce(mapping {|n| n + 1}, :<<, [])
    expect(actual).to eq([2,3,4])
  end

  it "creates a filtering transducer" do
    actual = [1,2,3,4,5].transduce(filtering(:even?), :<<, [])
    expect(actual).to eq([2,4])
  end

  it "creates a taking transducer" do
    actual = 1.upto(20).transduce(taking(5), :<<, [])
    expect(actual).to eq([1,2,3,4,5])
  end

  it "creates a cat transducer" do
    expect([[1,2],[3,4]].transduce(cat, :<<, [])).to eq([1,2,3,4])
  end

  it "creats a mapcat transducer with an object" do
    range_builder = Class.new do
      def xform(n) 0...n; end
    end.new
    mct = mapcat(range_builder)

    actual = [1,2,3].transduce(mct, :<<, [])
    expect(actual).to eq([0,0,1,0,1,2])
  end

  it "creats a mapcat transducer with a block" do
    actual = [1,2,3].transduce(mapcat {|n| 0...n}, :<<, [])
    expect(actual).to eq([0,0,1,0,1,2])
  end

  describe "composition" do
    example do
      td = compose(mapping {|a| [a.reduce(&:+)]}, cat)
      actual = [[1,2],[3,4]].transduce(td, :<<, [])
      expect(actual).to eq([3,7])
    end

    example do
      td = compose(taking(5),
                   mapping {|n| n + 1},
                   filtering(:even?))
      expect((1..20).transduce(td, :+, 0)).to eq(12)
    end
  end
end
