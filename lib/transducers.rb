require "transducers/version"

module Transducible
  def transduce(transducer, reducer, result)
    r = transducer.reducer(Transducers.reducer(reducer))
    each do |input|
      return result.val if Transducers::Reduced === result
      result = r.step(result, input)
    end
    result
  end
end

[Array, Enumerator, Range].each do |klass|
  klass.send(:include, Transducible)
end

module Transducers
  class Wrapper
    def initialize(reducer)
      @reducer = reducer
    end

    def step(result, input)
      result.send(@reducer, input)
    end
  end

  def reducer(reducer)
    Symbol === reducer ? Wrapper.new(reducer) : reducer
  end

  alias wrap reducer

  module_function :reducer, :wrap

  class Reduced
    attr_reader :val
    def initialize(val)
      @val = val
    end
  end

  class MappingTransducer
    class Factory
      def initialize(xform)
        @xform = xform
      end

      def reducer(reducer)
        MappingTransducer.new(reducer, @xform)
      end
    end

    def initialize(reducer, xform)
      @reducer = reducer
      @xform = xform
    end

    def step(result, input)
      @reducer.step(result, @xform.xform(input))
    end
  end

  def mapping(xform)
    MappingTransducer::Factory.new(xform)
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

    def step(result, input)
      rxf = input.transduce(PreservingReduced.new, @reducer, result)
    end
  end

  def cat
    CattingTransducer::Factory.new
  end

  def mapcat(f)
    compose(mapping(f), cat)
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
