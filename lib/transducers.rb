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

# Transducers are composable algorithmic transformations. See
# http://clojure.org/transducers before reading on.
#
# ## Terminology
#
# We need to expand the terminology a bit in order to map the concepts
# described on http://clojure.org/transducers to an OO language like
# Ruby.
#
# A _reducer_ is an object with a `call` method that takes a result
# (so far) and an input and returns a new result. This is similar to
# the blocks we pass to Ruby's `reduce` (a.k.a `inject`), and serves a
# similar role in _transducing process_.
#
# A _handler_ is an object with a `call` method that a reducer uses
# to process input. In a `map` operation, this would transform the
# input, and in a `filter` operation it would act as a predicate.
#
# A _transducer_ is an object that transforms a reducer by adding
# additional processing for each element in a collection of inputs.
#
# A _transducing process_ is invoked by calling
# `Transducers.transduce` with a transducer, a reducer, an optional
# initial value, and an input collection.
#
# Because Ruby doesn't come with free-floating handlers (e.g. Clojure's
# `inc` function) or reducing functions (e.g. Clojure's `conj`), we have
# to build these things ourselves.
#
# ## Examples
#
# ```ruby
# # handler
# inc = Class.new do
#         def call(input) input += 1 end
#       end.new
#
# # reducer
# appender = Class.new do
#              def call(result, input) result << input end
#            end.new
#
# # transducing process
# Transducers.transduce(Transducers.map(inc), appender, [], 0..9)
# #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# ```
#
# You can pass a `Symbol` or a `Block` to transducer constructors
# (`Transducers.map` in this example), so the above can be achieved
# more easily e.g.
#
# ```
# Transducers.transduce(Transducers.map(:succ),   appender, [], 0..9)
# #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# Transducers.transduce(Transducers.map {|n|n+1}, appender, [], 0..9)
# #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# ```
#
# You can omit the initial value if the reducer (`appender` in this
# example) provides one:
#
# ```
# def appender.init() [] end
# Transducers.transduce(Transducers.map {|n|n+1}, appender, 0..9)
# #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# ```
#
# You can also just pass a `Symbol` and an initial value instead of a
# reducer object, and the `transduce` method will build one for you.
#
# ```
# Transducers.transduce(Transducers.map {|n|n+1}, :<<, [], 0..9)
# #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
# ```
#
# ## Composition
#
# Imagine that you want to take a range of numbers, select all the even
# ones, double them, and then take the first 5. Here's one way to
# do that in Ruby:
#
# ```ruby
# (1..100).
#   select {|n| n.even?}.
#   map    {|n| n * 2}.
#   take(5)
# #=> [4, 8, 12, 16, 20]
# ```
#
# Here's the same process with transducers:
#
# ```ruby
# t = Transducers.compose(
#       Transducers.filter(:even?),
#       Transducers.map {|n| n * 2},
#       Transducers.take(5))
# Transducers.transduce(t, :<<, [], 1..100)
# #=> [4, 8, 12, 16, 20]
# ```
#
# Now that we've defined the transducer as a series of
# transformations, we can apply it to different contexts, e.g.
#
# ```ruby
# Transducers.transduce(t, :+, 0, 1..100)
# #=> 60
# Transducers.transduce(t, :*, 1, 1..100)
# #=> 122880
# ```
module Transducers
  extend self

  class Reducer
    class ReducingProc < Proc
      attr_reader :init

      def initialize(init, &proc)
        super(&proc)
        @init = init
      end

      def complete(result)
        result
      end
    end

    def self.new(init, sym=nil, &proc)
      if proc
        ReducingProc.new(init, &proc)
      else
        super
      end
    end

    attr_reader :init

    def initialize(init, sym)
      raise ArgumentError.new("No init provided") if init == :no_init_provided
      @init = init
      @sym = sym
    end

    def complete(result)
      result
    end

    def call(result, input)
      result.send(@sym, input)
    end
  end

  class Reduced
    attr_reader :val

    def initialize(val)
      @val = val
    end
  end

  class PreservingReduced
    def apply(reducer)
      @reducer = reducer
    end

    def call(result, input)
      ret = @reducer.call(result, input)
      Reduced === ret ? Reduced.new(ret) : ret
    end
  end

  # @api private
  class WrappingReducer
    class MethodHandler
      def initialize(method)
        @method = method
      end

      def call(input)
        input.send @method
      end
    end

    def initialize(reducer, handler=nil, &block)
      @reducer = reducer
      @handler = if block
                   block
                 elsif Symbol === handler
                   MethodHandler.new(handler)
                 else
                   handler
                 end
    end

    def init()
      @reducer.init
    end

    def complete(result)
      @reducer.complete(result)
    end
  end

  # @overload transduce(transducer, reducer, coll)
  # @overload transduce(transducer, reducer, init, coll)
  # @param [Transducer] transducer
  # @param [Reducer, Symbol, Block] reducer
  def transduce(transducer, reducer, init=:no_init_provided, coll)
    reducer = Reducer.new(init, reducer) unless reducer.respond_to?(:call)
    reducer = transducer.apply(reducer)
    result = init == :no_init_provided ? reducer.init : init
    case coll
    when Enumerable
      coll.each do |input|
        result = reducer.call(result, input)
        return result.val if Transducers::Reduced === result
        result
      end
    when String
      coll.each_char do |input|
        result = reducer.call(result, input)
        return result.val if Transducers::Reduced === result
        result
      end
    end
    reducer.complete(result)
  end

  # @api private
  class ComposedTransducer
    def initialize(*transducers)
      @transducers = transducers
    end

    def apply(reducer)
      @transducers.reverse.reduce(reducer) {|r,t| t.apply(r)}
    end
  end

  # @return [Transducer]
  # @param [Transducer, ...] transducers
  # Composes a series of transducers into a single transducer that you
  # can pass to `Transducers.transduce`. Transducers are applied left
  # to right.
  # @example
  #   T = Transducers
  #   divisible_by_3 = T.filter {|v| v % 3 == 0}
  #   times_4        = T.map    {|v| v * 4}
  #   t = T.compose(T.map(&:succ), T.filter(&:even?))
  #   T.transduce(t, :<<, [], 1.upto(9)
  #   #=> [2, 4, 6, 8, 10]
  def compose(*transducers)
    ComposedTransducer.new(*transducers)
  end

  # @api private
  class Transducer
    def initialize(handler, &block)
      @handler = handler
      @block = block
    end

    def reducer_class
      @reducer_class ||= self.class.const_get("Reducer")
    end

    def apply(reducer)
      reducer_class.new(reducer, @handler, &@block)
    end
  end

  # @api private
  class Map < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        @reducer.call(result, @handler.call(input))
      end
    end
  end

  # @api private
  class Filter < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        @handler.call(input) ? @reducer.call(result, input) : result
      end
    end
  end

  # @api private
  class Remove < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        @handler.call(input) ? result : @reducer.call(result, input)
      end
    end
  end

  # @api private
  class Take < Transducer
    class Reducer < WrappingReducer
      def initialize(reducer, n)
        super(reducer)
        @n = n
      end

      def call(result, input)
        @n -= 1
        ret = @reducer.call(result, input)
        @n > 0 ? ret : Reduced.new(ret)
      end
    end

    def initialize(n)
      @n = n
    end

    def apply(reducer)
      reducer_class.new(reducer, @n)
    end
  end

  # @api private
  class TakeWhile < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        @handler.call(input) ? @reducer.call(result, input) : Reduced.new(result)
      end
    end
  end

  # @api private
  class TakeNth < Transducer
    class Reducer < WrappingReducer
      def initialize(reducer, n)
        super(reducer)
        @n = n
        @count = 0
      end

      def call(result, input)
        @count += 1
        if @count % @n == 0
          @reducer.call(result, input)
        else
          result
        end
      end
    end

    def initialize(n)
      @n = n
    end

    def apply(reducer)
      reducer_class.new(reducer, @n)
    end
  end

  # @api private
  class Replace < Transducer
    class Reducer < WrappingReducer
      def initialize(reducer, smap)
        super(reducer)
        @smap = smap
      end

      def call(result, input)
        if @smap.has_key?(input)
          @reducer.call(result, @smap[input])
        else
          @reducer.call(result, input)
        end
      end
    end

    def initialize(smap)
      @smap = case smap
              when Hash
                smap
              else
                (0...smap.size).zip(smap).to_h
              end
    end

    def apply(reducer)
      reducer_class.new(reducer, @smap)
    end
  end

  # @api private
  class Keep < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        x = @handler.call(input)
        x.nil? ? result : @reducer.call(result, x)
      end
    end
  end

  # @api private
  class KeepIndexed < Transducer
    class Reducer < WrappingReducer
      def initialize(*)
        super
        @index = -1
      end

      def call(result, input)
        @index += 1
        x = @handler.call(@index, input)
        x.nil? ? result : @reducer.call(result, x)
      end
    end
  end

  # @api private
  class Drop < Transducer
    class Reducer < WrappingReducer
      def initialize(reducer, n)
        super(reducer)
        @n = n
      end

      def call(result, input)
        @n -= 1
        @n <= -1 ? @reducer.call(result, input) : result
      end
    end

    def initialize(n)
      @n = n
    end

    def apply(reducer)
      reducer_class.new(reducer, @n)
    end
  end

  # @api private
  class DropWhile < Transducer
    class Reducer < WrappingReducer
      def initalize(*)
        super
        @done_dropping = false
      end

      def call(result, input)
        @done_dropping ||= !@handler.call(input)
        @done_dropping ? @reducer.call(result, input) : result
      end
    end
  end

  # @api private
  class Dedupe < Transducer
    class Reducer < WrappingReducer
      def initialize(*)
        super
        @prior = :no_value_provided_for_transducer
      end

      def call(result, input)
        ret = input == @prior ? result : @reducer.call(result, input)
        @prior = input
        ret
      end
    end
  end

  # @api private
  class PartitionBy < Transducer
    class Reducer < WrappingReducer
      def initialize(*)
        super
        @a = []
        @prev_val = :no_value_provided_for_transducer
      end

      def complete(result)
        result = if @a.empty?
                   result
                 else
                   a = @a.dup
                   @a.clear
                   @reducer.call(result, a)
                 end
        @reducer.complete(result)
      end

      def call(result, input)
        prev_val = @prev_val
        val = @handler.call(input)
        @prev_val = val
        if val == prev_val || prev_val == :no_value_provided_for_transducer
          @a << input
          result
        else
          a = @a.dup
          @a.clear
          ret = @reducer.call(result, a)
          @a << input unless (Reduced === ret)
          ret
        end
      end
    end
  end

  # @api private
  class PartitionAll < Transducer
    class Reducer < WrappingReducer
      def initialize(reducer, n)
        super(reducer)
        @n = n
        @a = []
      end

      def call(result, input)
        @a << input
        if @a.size == @n
          a = @a.dup
          @a.clear
          @reducer.call(result, a)
        else
          result
        end
      end

      def complete(result)
        if @a.empty?
          result
        else
          a = @a.dup
          @a.clear
          @reducer.call(result, a)
        end
      end
    end

    def initialize(n)
      @n = n
    end

    def apply(reducer)
      reducer_class.new(reducer, @n)
    end
  end

  # @api private
  class Cat < Transducer
    class Reducer < WrappingReducer
      def call(result, input)
        Transducers.transduce(PreservingReduced.new, @reducer, result, input)
      end
    end
  end

  # @api private
  class RandomSampleHandler
    def initialize(prob)
      @prob = prob
    end

    def call(_)
      @prob > Random.rand
    end
  end

  # @api private
  def self.define_transducer_method(name)
    class_name = name.to_s.split("_").map(&:capitalize).join
    eval <<-HERE
def #{name}(handler=nil, &b)
  Transducers::#{class_name}.new(handler, &b)
end
HERE
  end

  # @!macro [new] common_transducer
  #   @return [Transducer]
  #   @method $1(handler=nil, &block)
  #   @param [Object, Symbol] handler
  #     Given an object that responds to `process`, uses it as the
  #     handler.  Given a `Symbol`, builds a handler whose `process`
  #     method will send `Symbol` to its argument.
  #   @param [Block] block <i>(optional)</i>
  #     Given a `Block`, builds a handler whose `process` method will
  #     call the block with its argument(s).

  # @macro common_transducer
  # Applies the given transformation to each element.
  define_transducer_method(:map)

  # @macro common_transducer
  # Keeps all elements for which predicate (handler or block) returns true.
  define_transducer_method(:filter)

  # @method take(n)
  # @return [Transducer]
  # @param [Fixnum] n
  # Takes n elements and drops the rest.
  define_transducer_method(:take)

  # @macro common_transducer
  # Removes all elements for which predicate (`handler` or `block`) returns true
  # (opposite of `filter`).
  define_transducer_method(:remove)

  # @macro common_transducer
  # Takes elements until predicate (`handler` or `block`) returns false.
  define_transducer_method(:take_while)

  # @method take_nth(n)
  # @return [Transducer]
  # @param [Fixnum] n
  # Takes only the nth element.
  define_transducer_method(:take_nth)

  # @method replace(replacement_pairs)
  # @return [Transducer]
  # @param [Hash] replacement_pairs a map of elements to replace
  #   (keys) to their replacements (values)
  # Given a `Hash` of replacement pairs, replaces each element that = a key
  # in `replacement_pairs` with its corresponding value.
  define_transducer_method(:replace)

  # @macro common_transducer
  # Keeps all elements for which predicate (handler or block) returns
  # a non-nil result.  This is similar to `filter`, but may include
  # `false`.
  define_transducer_method(:keep)

  # @macro common_transducer
  # @note The handler method or block must accept two arguments: the index of the item
  #   and the item itself.
  # @example
  #   T = Transducers
  #
  #   T.transduce(T.keep_indexed {|idx,val| val if idx.odd?}, :<<, [], [:a, :b, :c, :d, :e])
  #   #=> [:b, :d]
  #
  #   T.transduce(T.keep_indexed {|idx,val| idx if val > 0}, :<<, [],  [-9, 0, 29, -7, 45, 3, -8])
  #   #=> [2,4,5]
  # Provides a sequence of the non-nil results of `predicate.call(index, item)`
  define_transducer_method(:keep_indexed)

  # @method drop(n)
  # @return [Transducer]
  # @param [Fixnum] n
  # Drops the first n elements.
  define_transducer_method(:drop)

  # @macro common_transducer
  # Drops elements until predicate (`handler` or `block`) returns true.
  define_transducer_method(:drop_while)

  # @method dedupe()
  # @return [Transducer]
  # @example
  #   T.transduce(T.dedupe, :<<, [], [1,2,2,1,1,1,3,4,4,1,1,5])
  #   #=> [1,2,1,3,4,1,5]
  # Removes consecutive duplicate elements.
  define_transducer_method(:dedupe)

  # @macro common_transducer
  # Applies f (`handler` or `block`) to each value in input, splitting
  # the result each time f returns a new value.
  define_transducer_method(:partition_by)

  # @overload partition_all(n)
  # @return [Transducer]
  # @example
  #   T.transduce(T.partition_all(2), :<<, [], 1..6)
  #   #=> [[1,2],[3,4],[5,6]]
  #
  #   T.transduce(T.partition_all(2), :<<, [], 1..7)
  #   #=> [[1,2],[3,4],[5,6],[7]]
  # Produces a sequence of arrays of length `n` plus, possibly, one array
  # which contains the remaining elements.
  define_transducer_method(:partition_all)

  # @method cat
  # @return [Transducer]
  # Concats a series of collections.
  define_transducer_method(:cat)

  # @return [Transducer]
  # @param [Float] probability represents the probabilty each element will flow through.
  # Returns a random sample of input elements based on probability.
  def random_sample(probability)
    filter RandomSampleHandler.new(probability)
  end

  # @return [Transducer]
  # @param [Object, Symbol] handler
  #   Given an object that responds to `process`, uses it as the
  #   handler.  Given a `Symbol`, builds a handler whose `process`
  #   method will send `Symbol` to its argument.
  # @param [Block] block <i>(optional)</i>
  #   Given a `Block`, builds a handler whose `process` method will
  #   call the block with its argument(s).
  # Concats collections in the input, mapping over each one's
  # elements.
  def mapcat(handler=nil, &block)
    compose(map(handler, &block), cat)
  end
end
