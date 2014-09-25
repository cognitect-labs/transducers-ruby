require 'spec_helper'

RSpec.describe Transducers do
  include Transducers

  alias orig_expect expect

  def expect(expected, &actual)
    orig_expect(actual.call).to eq(expected)
  end

  it "creates a mapping transducer with an object" do
    inc = Class.new do
      def xform(n) n + 1 end
    end.new
    expect([2,3,4]) do
      [1,2,3].transduce(mapping(inc), :<<, [])
    end
  end

  it "creates a mapping transducer with a block" do
    expect([2,3,4]) do
      [1,2,3].transduce(mapping {|n| n + 1}, :<<, [])
    end
  end

  it "creates a filtering transducer" do
    expect([2,4]) do
      [1,2,3,4,5].transduce(filtering(:even?), :<<, [])
    end
  end

  it "creates a taking transducer" do
    expect([1,2,3,4,5]) do
      1.upto(20).transduce(taking(5), :<<, [])
    end
  end

  it "creates a cat transducer" do
    expect([1,2,3,4]) do
      [[1,2],[3,4]].transduce(cat, :<<, [])
    end
  end

  it "creates a mapcat transducer with an object" do
    range_builder = Class.new do
      def xform(n) 0...n; end
    end.new

    expect([0,0,1,0,1,2]) do
      [1,2,3].transduce(mapcat(range_builder), :<<, [])
    end
  end

  it "creates a mapcat transducer with a block" do
    expect([0,0,1,0,1,2]) do
      [1,2,3].transduce(mapcat {|n| 0...n}, :<<, [])
    end
  end

  describe "composition" do
    example do
      expect([3,7]) do
        td = compose(mapping {|a| [a.reduce(&:+)]}, cat)
        [[1,2],[3,4]].transduce(td, :<<, [])
      end
    end

    example do
      expect(12) do
        td = compose(taking(5),
                   mapping {|n| n + 1},
                   filtering(:even?))
        (1..20).transduce(td, :+, 0)
      end
    end
  end
end
