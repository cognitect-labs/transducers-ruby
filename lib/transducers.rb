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
  def transduce(transducer, reducer, init=:init_not_supplied , coll)
    r = transducer.apply(Transducers.reducer(init, reducer))
    result = (init == :init_not_supplied) ? r.init : init
    m = case coll
        when Enumerable
          :each
        when String
          :each_char
        end
    coll.send(m) do |input|
      return result.val if Transducers::Reduced === result
      result = r.step(result, input)
    end
    result
  end

  module_function :transduce

  class Reducer
    attr_reader :init

    def initialize(init, sym=nil, &block)
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

    def result(result)
      result
    end
  end

  def reducer(init, sym_or_reducer=nil, &block)
    if sym_or_reducer.respond_to?(:step)
      sym_or_reducer
    else
      Reducer.new(init, sym_or_reducer, &block)
    end
  end

  module_function :reducer

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

    def result(result)
      @reducer.result(result)
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

  module_function :mapping, :filtering, :taking, :cat, :compose, :mapcat
end
