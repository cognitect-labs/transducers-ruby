require "transducers/version"

module Transducers
  def transduce(transducer, reducer, init=:init_not_supplied , coll)
    r = transducer.apply(Transducers.reducer(init, reducer))
    result = (init == :init_not_supplied) ? r.init : init
    return transduce_string(r, result, coll) if String === coll
    coll.each do |input|
      return result.val if Transducers::Reduced === result
      result = r.step(result, input)
    end
    result
  end

  def transduce_string(reducer, result, str)
    str.each_char do |input|
      return result.val if Transducers::Reduced === result
      result = reducer.step(result, input)
    end
    result
  end

  module_function :transduce, :transduce_string

  class Reducer
    attr_reader :init

    def initialize(init, sym=:no_sym, &block)
      @init = init
      @sym = sym
      @block = block
      (class << self; self; end).class_eval do
        if block
          def step(result, input)
            @block.call(result, input)
          end
        else
          def step(result, input)
            result.send(@sym, input)
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

  class Reduced
    attr_reader :val
    def initialize(val)
      @val = val
    end
  end

  class BaseReducer
    def initialize(reducer)
      @reducer = reducer
    end

    def init()
      @reducer.respond_to?(:init) ? @reducer.init : nil
    end

    def result(result)
      @reducer.result(result)
    end
  end

  class MappingTransducer
    class Reducer < BaseReducer
      def initialize(reducer, xform)
        super(reducer)
        @xform = xform
      end

      def step(result, input)
        @reducer.step(result, @xform.xform(input))
      end
    end

    class XForm
      def initialize(block)
        @block = block
      end

      def xform(input)
        @block.call(input)
      end
    end

    def initialize(xform, &block)
      @xform = block ? XForm.new(block) : xform
    end

    def apply(reducer)
      Reducer.new(reducer, @xform)
    end
  end

  def mapping(xform=nil, &block)
    MappingTransducer.new(xform, &block)
  end

  class FilteringTransducer
    class Reducer < BaseReducer
      def initialize(reducer, pred)
        super(reducer)
        @pred = pred
      end

      def step(result, input)
        input.send(@pred) ? @reducer.step(result, input) : result
      end
    end

    def initialize(pred)
      @pred = pred
    end

   def apply(reducer)
      Reducer.new(reducer, @pred)
    end
  end

  def filtering(pred)
    FilteringTransducer.new(pred)
  end

  class TakingTransducer
    class Reducer < BaseReducer
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
      Reducer.new(reducer, @n)
    end
  end

  def taking(n)
    TakingTransducer.new(n)
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

  class CattingTransducer
    class Reducer < BaseReducer
      def step(result, input)
        Transducers.transduce(PreservingReduced.new, @reducer, result, input)
      end
    end

    def apply(reducer)
      Reducer.new(reducer)
    end
  end

  def cat
    CattingTransducer.new
  end

  def mapcat(f=nil, &b)
    compose(mapping(f, &b), cat)
  end

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

  module_function :mapping, :filtering, :taking, :cat, :compose, :mapcat
end
