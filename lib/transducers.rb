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

  module_function :transduce

  class Reducer
    attr_reader :init

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

    def complete(result)
      result
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
  class BaseReducer
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

  class BaseTransducer
    def initialize(handler, &block)
      @handler = handler
      @block = block
    end
  end

  # @api private
  class MappingTransducer < BaseTransducer
    class MappingReducer < BaseReducer
      def step(result, input)
        @reducer.step(result, @handler.process(input))
      end
    end

    def apply(reducer)
      MappingReducer.new(reducer, @handler, &@block)
    end
  end

  def mapping(process=nil, &block)
    MappingTransducer.new(process, &block)
  end

  # @api private
  class FilteringTransducer < BaseTransducer
    class FilteringReducer < BaseReducer
      def step(result, input)
        @handler.process(input) ? @reducer.step(result, input) : result
      end
    end

    def apply(reducer)
      FilteringReducer.new(reducer, @handler, &@block)
    end
  end

  def filtering(pred=nil, &block)
    FilteringTransducer.new(pred, &block)
  end

  # @api private
  class RemovingTransducer < BaseTransducer
    class RemovingReducer < BaseReducer
      def step(result, input)
        @handler.process(input) ? result : @reducer.step(result, input)
      end
    end

    def apply(reducer)
      RemovingReducer.new(reducer, @handler, &@block)
    end
  end

  def removing(pred=nil, &block)
    RemovingTransducer.new(pred, &block)
  end

  # @api private
  class TakingTransducer
    class TakingReducer < BaseReducer
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
      TakingReducer.new(reducer, @n)
    end
  end

  def taking(n)
    TakingTransducer.new(n)
  end

  # @api private
  class TakingWhileTransducer < BaseTransducer
    class TakingWhileReducer < BaseReducer
      def step(result, input)
        @handler.process(input) ? @reducer.step(result, input) : Reduced.new(result)
      end
    end

    def apply(reducer)
      TakingWhileReducer.new(reducer, @handler, &@block)
    end
  end

  def taking_while(pred=nil, &block)
    TakingWhileTransducer.new(pred, &block)
  end

  class DroppingTransducer
    class Reducer < BaseReducer
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
      Reducer.new(reducer, @n)
    end
  end

  def dropping(n)
    DroppingTransducer.new(n)
  end

  # @api private
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
  class CattingTransducer
    class CattingReducer < BaseReducer
      def step(result, input)
        Transducers.transduce(PreservingReduced.new, @reducer, result, input)
      end
    end

    def apply(reducer)
      CattingReducer.new(reducer)
    end
  end

  def cat
    CattingTransducer.new
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

  def compose(*transducers)
    ComposedTransducer.new(*transducers)
  end

  def mapcat(process=nil, &b)
    compose(mapping(process, &b), cat)
  end

  module_function :mapping, :filtering, :taking, :cat, :compose, :mapcat, :dropping, :taking_while, :removing
end
