require "transducers/version"

module Transducers
  def transduce(transducer, reducer, init_or_coll, coll=nil)
    r = transducer.reducer(Transducers.reducer(reducer))
    result = coll ? init_or_coll : r.init
    (coll || init_or_coll).each do |input|
      return result.val if Transducers::Reduced === result
      result = r.step(result, input)
    end
    result
  end

  module_function :transduce

  class Reducer
    def initialize(sym, init=nil)
      @sym = sym
      @init = init
    end

    def init
      @init
    end

    def result(result)
      result
    end

    def step(result, input)
      result.send(@sym, input)
    end
  end

  INITIAL_VALUES = {
    :<< => [],
    :+  => 0
  }

  def reducer(reducer)
    if Symbol === reducer
      Reducer.new(reducer, INITIAL_VALUES[reducer])
    else
      reducer
    end
  end

  module_function :reducer

  class Reduced
    attr_reader :val
    def initialize(val)
      @val = val
    end
  end

  class MappingTransducer
    class XForm
      def initialize(block)
        @block = block
      end

      def xform(input)
        @block.call(input)
      end
    end

    class Factory
      def initialize(xform, &block)
        @xform = block ? XForm.new(block) : xform
      end

      def reducer(reducer)
        MappingTransducer.new(reducer, @xform)
      end
    end

    def initialize(reducer, xform)
      @reducer = reducer
      @xform = xform
    end

    def init()
      @reducer.init()
    end

    def result(result)
      @reducer.result(result)
    end

    def step(result, input)
      @reducer.step(result, @xform.xform(input))
    end
  end

  def mapping(xform=nil, &block)
    MappingTransducer::Factory.new(xform, &block)
  end

  class FilteringTransducer
    class Factory
      def initialize(pred)
        @pred = pred
      end

      def reducer(reducer)
        FilteringTransducer.new(reducer, @pred)
      end
    end

    def initialize(reducer, pred)
      @reducer = reducer
      @pred = pred
    end

    def init()
      @reducer.init()
    end

    def result(result)
      @reducer.result(result)
    end

    def step(result, input)
      input.send(@pred) ? @reducer.step(result, input) : result
    end
  end

  def filtering(pred)
    FilteringTransducer::Factory.new(pred)
  end

  class TakingTransducer
    class Factory
      def initialize(n)
        @n = n
      end

      def reducer(reducer)
        TakingTransducer.new(reducer, @n)
      end
    end

    def initialize(reducer, n)
      @reducer = reducer
      @n = n
    end

    def init()
      @reducer.init()
    end

    def result(result)
      @reducer.result(result)
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

  def taking(n)
    TakingTransducer::Factory.new(n)
  end

  class PreservingReduced
    def reducer(reducer)
      @reducer = reducer
    end

    def step(result, input)
      ret = @reducer.step(result, input)
      if Reduced === ret
        Reduced.new(ret)
      else
        ret
      end
    end
  end

  class CattingTransducer
    class Factory
      def reducer(reducer)
        CattingTransducer.new(reducer)
      end
    end

    def initialize(reducer)
      @reducer = reducer
    end

    def init()
      @reducer.init()
    end

    def result(result)
      @reducer.result(result)
    end

    def step(result, input)
      rxf = Transducers.transduce(PreservingReduced.new, @reducer, result, input)
    end
  end

  def cat
    CattingTransducer::Factory.new
  end

  def mapcat(f=nil, &b)
    compose(mapping(f, &b), cat)
  end

  class ComposedTransducer
    class Factory
      def initialize(*transducers)
        @transducers = transducers
      end

      def reducer(reducer)
        @transducers.reverse.reduce(reducer) {|r,t| t.reducer(r)}
      end
    end
  end

  def compose(*transducers)
    ComposedTransducer::Factory.new(*transducers)
  end

  module_function :mapping, :filtering, :taking, :cat, :compose, :mapcat
end
