require "transducers/version"

module Transducible
  def transduce(transducer, reducer, result)
    r = transducer.reducer(Reducers.reducer(reducer))
    each { |input| result = r.step(result, input) }
    result
  end
end

[Array, Enumerator, Range].each do |klass|
  klass.send(:include, Transducible)
end

module Reducers
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
end

module Transducers

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

  module_function :mapping, :filtering, :compose
end
