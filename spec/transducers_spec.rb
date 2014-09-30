require 'spec_helper'

RSpec.describe Transducers do
  include Transducers

  alias orig_expect expect

  def expect(expected, &actual)
    orig_expect(actual.call).to eq(expected)
  end

  it "creates a mapping transducer with a block" do
    expect([2,3,4]) do
      transduce(mapping {|n| n + 1}, :<<, [], [1,2,3])
    end
  end

  it "creates a mapping transducer with a Symbol" do
    expect([2,3,4]) do
      transduce(mapping(:succ), :<<, [], [1,2,3])
    end
  end

  it "creates a mapping transducer with an object" do
    inc = Class.new do
      def xform(n) n + 1 end
    end.new
    expect([2,3,4]) do
      transduce(mapping(inc), :<<, [], [1,2,3])
    end
  end

  it "creates a filtering transducer with a Symbol" do
    expect([2,4]) do
      transduce(filtering(:even?), :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a filtering transducer with a Block" do
    expect([2,4]) do
      transduce(filtering {|x| x.even?}, :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a taking transducer" do
    expect([1,2,3,4,5]) do
      transduce(taking(5), :<<, [], 1.upto(20))
    end
  end

  it "creates a cat transducer" do
    expect([1,2,3,4]) do
      transduce(cat, :<<, [], [[1,2],[3,4]])
    end
  end

  it "creates a mapcat transducer with an object" do
    range_builder = Class.new do
      def xform(n) 0...n; end
    end.new

    expect([0,0,1,0,1,2]) do
      transduce(mapcat(range_builder), :<<, [], [1,2,3])
    end
  end

  it "creates a mapcat transducer with a block" do
    expect([0,0,1,0,1,2]) do
      transduce(mapcat {|n| 0...n}, :<<, [], [1,2,3])
    end
  end

  it "transduces with a String" do
    expect("THIS") do
      transduce(mapping {|c| c.upcase},
                Transducers::Reducer.new("") {|r,i| r << i},
                "this")
    end
  end

  it "inits to nil when there is no init fn on the reducer" do
    expect([nil,2,3,4]) do
      r = Class.new { define_method(:step) {|r,i| r ? (r << i) : [r, i]} }.new
      transduce(mapping {|n| n + 1}, r, [1,2,3])
    end
  end

  describe "composition" do
    example do
      expect([3,7]) do
        td = compose(mapping {|a| [a.reduce(&:+)]}, cat)
        transduce(td, :<<, [], [[1,2],[3,4]])
      end
    end

    example do
      expect(12) do
        td = compose(taking(5),
                   mapping {|n| n + 1},
                   filtering(:even?))
        transduce(td, :+, 0, 1..20)
      end
    end
  end
end
