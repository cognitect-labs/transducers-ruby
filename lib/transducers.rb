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

  # @api private
  class Reduced
    attr_reader :val

    def initialize(val)
      @val = val
    end
  end

  # @api private
  class PreservingReduced
    def apply(reducer)
      @reducer = reducer
    end

    def call(result, input)
      ret = @reducer.call(result, input)
      Reduced === ret ? Reduced.new(ret) : ret
    end
  end

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

  # @api private
  class BaseTransducer
    class << self
      attr_reader :reducer_class

      def define_reducer_class(&block)
        @reducer_class = Class.new(WrappingReducer)
        @reducer_class.class_eval(&block)
      end
    end

    def initialize(handler, &block)
      @handler = handler
      @block = block
    end

    def reducer_class
      self.class.reducer_class
    end
  end

  class << self
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

    def self.define_transducer_class(name, &block)
      t = Class.new(BaseTransducer)
      t.class_eval(&block)
      unless t.instance_methods.include? :apply
        t.class_eval do
          define_method :apply do |reducer|
            reducer_class.new(reducer, @handler, &@block)
          end
        end
      end

      Transducers.send(:define_method, name) do |handler=nil, &b|
        t.new(handler, &b)
      end

      Transducers.send(:module_function, name)
    end

    # @macro [new] common_transducer
    #   @return [Transducer]
    #   @method $1(handler=nil, &block)
    #   @param [Object, Symbol] handler
    #     Given an object that responds to +process+, uses it as the
    #     handler.  Given a +Symbol+, builds a handler whose +process+
    #     method will send +Symbol+ to its argument.
    #   @param [Block] block <i>(optional)</i>
    #     Given a +Block+, builds a handler whose +process+ method will
    #     call the block with its argument(s).
    # Returns a transducer that adds a map transformation to the
    # reducer stack.
    define_transducer_class :map do
      define_reducer_class do
        def call(result, input)
          @reducer.call(result, @handler.call(input))
        end
      end
    end

    # @macro common_transducer
    define_transducer_class :filter do
      define_reducer_class do
        def call(result, input)
          @handler.call(input) ? @reducer.call(result, input) : result
        end
      end
    end

    # @macro common_transducer
    define_transducer_class :remove do
      define_reducer_class do
        def call(result, input)
          @handler.call(input) ? result : @reducer.call(result, input)
        end
      end
    end

    # @method take(n)
    # @return [Transducer]
    define_transducer_class :take do
      define_reducer_class do
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

    # @macro common_transducer
    define_transducer_class :take_while do
      define_reducer_class do
        def call(result, input)
          @handler.call(input) ? @reducer.call(result, input) : Reduced.new(result)
        end
      end
    end

    # @method take_nth(n)
    # @return [Transducer]
    define_transducer_class :take_nth do
      define_reducer_class do
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

    # @method replace(source_map)
    # @return [Transducer]
    define_transducer_class :replace do
      define_reducer_class do
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

    # @macro common_transducer
    define_transducer_class :keep do
      define_reducer_class do
        def call(result, input)
          x = @handler.call(input)
          x.nil? ? result : @reducer.call(result, x)
        end
      end
    end

    # @macro common_transducer
    # @note the handler for this method requires two arguments: the
    #   index and the input.
    define_transducer_class :keep_indexed do
      define_reducer_class do
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

    # @method drop(n)
    # @return [Transducer]
    define_transducer_class :drop do
      define_reducer_class do
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

    # @macro common_transducer
    define_transducer_class :drop_while do
      define_reducer_class do
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

    # @method dedupe
    # @return [Transducer]
    define_transducer_class :dedupe do
      define_reducer_class do
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

    # @method partition_by
    # @return [Transducer]
    define_transducer_class :partition_by do
      define_reducer_class do
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

    # @method partition_all
    # @return [Transducer]
    define_transducer_class :partition_all do
      define_reducer_class do
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
    class RandomSampleHandler
      def initialize(prob)
        @prob = prob
      end

      def call(_)
        @prob > Random.rand
      end
    end

    # @return [Transducer]
    def random_sample(prob)
      filter RandomSampleHandler.new(prob)
    end

    # @method cat
    # @return [Transducer]
    define_transducer_class :cat do
      define_reducer_class do
        def call(result, input)
          Transducers.transduce(PreservingReduced.new, @reducer, result, input)
        end
      end
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
    # Composes a series of transducers into a single transducer that
    # you can pass to `Transducers.transduce`.
    # @example
    #   t = Transducers.compose(
    #         Transducers.map(&:succ),
    #         Transducers.filter(&:even?)
    #       )
    #   Transducers.transduce(t, ...)
    def compose(*transducers)
      ComposedTransducer.new(*transducers)
    end

    # @return [Transducer]
    def mapcat(handler=nil, &block)
      compose(map(handler, &block), cat)
    end
  end
end
