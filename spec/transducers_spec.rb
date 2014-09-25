require 'spec_helper'

RSpec.describe Transducers do
  include Transducers

  it "creates a mapping transducer with an object" do
    inc = Class.new do
      def xform(n) n + 1 end
    end.new
    transducer = mapping(inc)
    actual = [1,2,3].transduce(transducer, :<<, [])
    expect(actual).to eq([2,3,4])
  end

  it "creates a mapping transducer with a block" do
    transducer = mapping {|n| n + 1}
    actual = [1,2,3].transduce(transducer, :<<, [])
    expect(actual).to eq([2,3,4])
  end

  it "creates a filtering transducer" do
    transducer = filtering(:even?)
    actual = [1,2,3,4,5].transduce(transducer, :<<, [])
    expect(actual).to eq([2,4])
  end

  it "creates a taking transducer" do
    transducer = taking(5)
    actual = 1.upto(20).transduce(transducer, :<<, [])
    expect(actual).to eq([1,2,3,4,5])
  end

  it "creates a catting transducer" do
    expect([[1,2],[3,4]].transduce(cat, :<<, [])).to eq([1,2,3,4])
  end

  it "creats a mapcat transducer with an object" do
    range_builder = Class.new do
      def xform(n) 0...n; end
    end.new
    td = mapcat(range_builder)

    actual = [1,2,3].transduce(td, :<<, [])
    expect(actual).to eq([0,0,1,0,1,2])
  end

  it "creats a mapcat transducer with a block" do
    td = mapcat {|n| 0...n}
    actual = [1,2,3].transduce(td, :<<, [])
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
