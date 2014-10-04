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

# Transducers are composable algorithmic transformations.
module Transducers
  class Reducer
    def initialize(init, sym=nil, &block)
      raise ArgumentError.new("No init provided") if init == :no_init_provided
      @init = init
      if sym
        @sym = sym
        (class << self; self; end).class_eval do
          def step(result, input)
            result.send(@sym, input)
          end
        end
      else
        @block = block
        (class << self; self; end).class_eval do
          def step(result, input)
            @block.call(result, input)
          end
        end
      end
    end

    def init()           @init  end
    def complete(result) result end
    def step(result, input)
      # placeholder for docs - overwritten in initalize
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

    def step(result, input)
      ret = @reducer.step(result, input)
      Reduced === ret ? Reduced.new(ret) : ret
    end
  end

  # @api private
  class WrappingReducer
    class BlockHandler
      def initialize(block)
        @block = block
      end

      def process(input)
        @block.call(input)
      end
    end

    class MethodHandler
      def initialize(method)
        @method = method
      end

      def process(input)
        input.send @method
      end
    end

    def initialize(reducer, process=nil, &block)
      @reducer = reducer
      @handler = if block
                   BlockHandler.new(block)
                 elsif Symbol === process
                   MethodHandler.new(process)
                 else
                   process
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
    def transduce(transducer, reducer, init=:no_init_provided, coll)
      reducer = Reducer.new(init, reducer) unless reducer.respond_to?(:step)
      reducer = transducer.apply(reducer)
      result = init == :no_init_provided ? reducer.init : init
      m = case coll
          when Enumerable then :each
          when String     then :each_char
          end
      coll.send(m) do |input|
        return result.val if Transducers::Reduced === result
        result = reducer.step(result, input)
      end
      result
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


    # @return [Transducer]
    define_transducer_class "map" do
      define_reducer_class do
        def step(result, input)
          @reducer.step(result, @handler.process(input))
        end
      end
    end

    # @return [Transducer]
    define_transducer_class "filter" do
      define_reducer_class do
        def step(result, input)
          @handler.process(input) ? @reducer.step(result, input) : result
        end
      end
    end

    # @return [Transducer]
    define_transducer_class "remove" do
      define_reducer_class do
        def step(result, input)
          @handler.process(input) ? result : @reducer.step(result, input)
        end
      end
    end

    # @return [Transducer]
    define_transducer_class "take" do
      define_reducer_class do
        def initialize(reducer, n)
          super(reducer)
          @n = n
        end

        def step(result, input)
          @n -= 1
          if @n == -1
            Reduced.new(result)
          else
            @reducer.step(result, input)
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

    # @return [Transducer]
    define_transducer_class "take_while" do
      define_reducer_class do
        def step(result, input)
          @handler.process(input) ? @reducer.step(result, input) : Reduced.new(result)
        end
      end
    end

    # @return [Transducer]
    define_transducer_class "take_nth" do
      define_reducer_class do
        def initialize(reducer, n)
          super(reducer)
          @n = n
          @count = 0
        end

        def step(result, input)
          @count += 1
          if @count % @n == 0
            @reducer.step(result, input)
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

    # @return [Transducer]
    define_transducer_class "replace" do
      define_reducer_class do
        def initialize(reducer, smap)
          super(reducer)
          @smap = smap
        end

        def step(result, input)
          if @smap.has_key?(input)
            @reducer.step(result, @smap[input])
          else
            @reducer.step(result, input)
          end
        end
      end

      def initialize(smap)
        @smap = case smap
                when Hash
                  smap
                else
                  smap.reduce({}) {|h,v| h[h.count] = v; h}
                end
      end

      def apply(reducer)
        reducer_class.new(reducer, @smap)
      end
    end

    # @return [Transducer]
    define_transducer_class "drop" do
      define_reducer_class do
        def initialize(reducer, n)
          super(reducer)
          @n = n
        end

        def step(result, input)
          @n -= 1

          if @n <= -1
            @reducer.step(result, input)
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

    # @return [Transducer]
    define_transducer_class "drop_while" do
      define_reducer_class do
        def initalize(*)
          super
          @done_dropping = false
        end

        def step(result, input)
          @done_dropping ||= !@handler.process(input)
          @done_dropping ? @reducer.step(result, input) : result
        end
      end
    end


    # @return [Transducer]
    define_transducer_class "cat" do
      define_reducer_class do
        def step(result, input)
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
    def compose(*transducers)
      ComposedTransducer.new(*transducers)
    end

    # @return [Transducer]
    def mapcat(process=nil, &b)
      compose(map(process, &b), cat)
    end
  end
end
