# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'spec_helper'

RSpec.describe Transducers do
  alias orig_expect expect

  T = Transducers

  def expect(expected, &actual)
    orig_expect(actual.call).to eq(expected)
  end

  it "creates a map transducer with a block" do
    expect([2,3,4]) do
      T.transduce(T.map {|n| n + 1}, :<<, [], [1,2,3])
    end
  end

  it "creates a map transducer with a Symbol" do
    expect([2,3,4]) do
      T.transduce(T.map(:succ), :<<, [], [1,2,3])
    end
  end

  it "creates a map transducer with an object that implements process" do
    inc = Class.new do
      def process(n) n + 1 end
    end.new

    expect([2,3,4]) do
      T.transduce(T.map(inc), :<<, [], [1,2,3])
    end
  end

  it "creates a filter transducer with a Symbol" do
    expect([2,4]) do
      T.transduce(T.filter(:even?), :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a filter transducer with a Block" do
    expect([2,4]) do
      T.transduce(T.filter {|x| x.even?}, :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a filter transducer with an object that implements process" do
    expect([2,4]) do
      even = Class.new do
        def process(n) n.even? end
      end.new
      T.transduce(T.filter(even), :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a remove transducer with a Symbol" do
    expect([1,3,5]) do
      T.transduce(T.remove(:even?), :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a remove transducer with a Block" do
    expect([1,3,5]) do
      T.transduce(T.remove {|x| x.even?}, :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a remove transducer with an object that implements process" do
    expect([1,3,5]) do
      even = Class.new do
        def process(n) n.even? end
      end.new
      T.transduce(T.remove(even), :<<, [], [1,2,3,4,5])
    end
  end

  it "creates a take transducer" do
    expect([1,2,3,4,5]) do
      T.transduce(T.take(5), :<<, [], 1.upto(20))
    end
  end

  it "creates a take_while transducer" do
    expect([1,2,3,4,5]) do
      T.transduce(T.take_while {|n| n < 6}, :<<, [], 1.upto(20))
    end

    expect([1,1,1]) do
      T.transduce(T.take_while {|n| n.odd?}, :<<, [], [1,1,1,2,3])
    end
  end

  it "creates a take_nth transducer" do
    expect([3,6,9,12]) do
      T.transduce(T.take_nth(3), :<<, [], 1..12)
    end

    expect([3,6,9,12]) do
      T.transduce(T.take_nth(3), :<<, [], 1..13)
    end

    expect([3,6,9,12]) do
      T.transduce(T.take_nth(3), :<<, [], 1..14)
    end
  end

  it "creates a drop transducer" do
    expect([16,17,18,19,20]) do
      T.transduce(T.drop(15), :<<, [], 1.upto(20))
    end
  end

  it "creates a drop_while transducer" do
    expect((6..20).to_a) do
      T.transduce(T.drop_while {|n| n < 6}, :<<, [], 1.upto(20))
    end

    expect([2,3]) do
      T.transduce(T.drop_while {|n| n.odd?}, :<<, [], [1,1,1,2,3])
    end
  end

  it "creates a replace transducer" do
    expect([:zeroth, :second, :fourth, :zeroth]) do
      T.transduce(T.replace([:zeroth, :first, :second, :third, :fourth]), :<<, [],  [0, 2, 4, 0])
    end

    expect([:codes, :zero, :one, :two, :zero]) do
      T.transduce(T.replace({0 => :zero, 1 => :one, 2 => :two}), :<<, [],  [:codes, 0, 1, 2, 0])
    end
  end

  it "creates a keep transducer" do
    expect([false, true, false, true, false]) do
      T.transduce(T.keep(:even?), :<<, [], 1..5)
    end

    expect([1,3,5,7,9]) do
      T.transduce(T.keep {|n| n if n.odd?}, :<<, [], 0..9)
    end
  end

  it "creates a keep_indexed transducer" do
    expect([:b, :d]) do
      T.transduce(T.keep_indexed {|i,v| v if i.odd?}, :<<, [], [:a, :b, :c, :d, :e])
    end

    expect([2,4,5]) do
      T.transduce(T.keep_indexed {|i,v| i if v > 0}, :<<, [],  [-9, 0, 29, -7, 45, 3, -8])
    end

    expect([2,4,5]) do
      handler = Class.new do
        def process(i,v)
          i if v > 0
        end
      end
      T.transduce(T.keep_indexed(handler.new), :<<, [],  [-9, 0, 29, -7, 45, 3, -8])
    end
  end

  it "creates a dedupe transducer" do
    expect([1,2,1,3,4,1,5]) do
      T.transduce(T.dedupe, :<<, [], [1,2,2,1,1,1,3,4,4,1,1,5])
    end
  end

  it "creates a cat transducer" do
    expect([1,2,3,4]) do
      T.transduce(T.cat, :<<, [], [[1,2],[3,4]])
    end
  end

  it "creates a mapcat transducer with an object" do
    range_builder = Class.new do
      def process(n) 0...n; end
    end.new

    expect([0,0,1,0,1,2]) do
      T.transduce(T.mapcat(range_builder), :<<, [], [1,2,3])
    end
  end

  it "creates a mapcat transducer with a block" do
    expect([0,0,1,0,1,2]) do
      T.transduce(T.mapcat {|n| 0...n}, :<<, [], [1,2,3])
    end
  end

  it "creates a partition_by transducer" do
    expect([[1,2],[3],[4,5]]) do
      T.transduce(T.partition_by {|n| n == 3}, :<<, [], 1..5)
    end

    expect([["A"],["B","B"],["A"]]) do
      T.transduce(T.partition_by {|n|n}, :<<, [], "ABBA")
    end
  end

  it "creates a partition_all transducer" do
    expect([[1,2],[3,4],[5,6]]) do
      T.transduce(T.partition_all(2), :<<, [], 1..6)
    end

    expect([[1,2],[3,4],[5,6],[7]]) do
      T.transduce(T.partition_all(2), :<<, [], 1..7)
    end
  end

  it "transduces a String" do
    expect("THIS") do
      T.transduce(T.map {|c| c.upcase},
                Transducers::Reducer.new("") {|r,i| r << i},
                "this")
    end
  end

  it "transduces a range" do
    expect([2,3,4]) do
      T.transduce(T.map(:succ), :<<, [], 1..3)
    end
  end

  it "raises when no initial value method is defined on the reducer" do
    orig_expect do
      r = Class.new { def step(_,_) end }.new
      T.transduce(T.map(:succ), r, [1,2,3])
    end.to raise_error(NoMethodError)
  end

  it "raises when it receives a symbol but no initial value" do
    orig_expect do
      T.transduce(T.map(:succ), :<<, [1,2,3])
    end.to raise_error(ArgumentError, "No init provided")
  end

  describe "composition" do
    example do
      expect([3,7]) do
        td = T.compose(T.map {|a| [a.reduce(&:+)]}, T.cat)
        T.transduce(td, :<<, [], [[1,2],[3,4]])
      end
    end

    example do
      expect(12) do
        td = T.compose(T.take(5),
                       T.map {|n| n + 1},
                       T.filter(:even?))
        T.transduce(td, :+, 0, 1..20)
      end
    end
  end
end
