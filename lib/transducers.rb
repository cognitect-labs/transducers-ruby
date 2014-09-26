require "transducers/version"

module Transducers
  def transduce(transducer, reducer, init_or_coll, coll=nil)
    r = transducer.reducer(Transducers.reducer(reducer, init_or_coll))
    result = coll ? init_or_coll : r.init
    (coll || init_or_coll).each do |input|
      return result.val if Transducers::Reduced === result
      result = r.step(result, input)
    end
    result
  end

  module_function :transduce

  class Reducer
    CACHE = {}
    attr_reader :init

    def initialize(sym_or_init, init=nil, &block)
      @sym = init ? sym_or_init : nil
      @init = init ? init : sym_or_init
      @block = block
      CACHE[@sym] = self if Symbol === @sym
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

  {
    :<< => [],
    :+  => 0,
    :-  => 0,
    :*  => 1
  }.each {|k,v| Reducer.new(k,v)}

  def reducer(reducer_or_init, init=nil, &block)
    return reducer_or_init if reducer_or_init.respond_to?(:step)
    Reducer::CACHE[reducer_or_init] ||
      (Symbol === reducer_or_init ? Reducer.new(reducer_or_init, init, &block) : reducer_or_init)
  end

  module_function :reducer

  class Reduced
    attr_reader :val
    def initialize(val)
      @val = val
    end
  end

  class MappingTransducer
    class Reducer
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

    def reducer(reducer)
      Reducer.new(reducer, @xform)
    end
  end

  def mapping(xform=nil, &block)
    MappingTransducer.new(xform, &block)
  end

  class FilteringTransducer
    class Reducer
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

    def initialize(pred)
      @pred = pred
    end

    def reducer(reducer)
      Reducer.new(reducer, @pred)
    end
  end

  def filtering(pred)
    FilteringTransducer.new(pred)
  end

  class TakingTransducer
    class Reducer
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
    def initialize(n)
      @n = n
    end

    def reducer(reducer)
      Reducer.new(reducer, @n)
    end
  end

  def taking(n)
    TakingTransducer.new(n)
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
    class Reducer
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

    def reducer(reducer)
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

    def reducer(reducer)
      @transducers.reverse.reduce(reducer) {|r,t| t.reducer(r)}
    end
  end

  def compose(*transducers)
    ComposedTransducer.new(*transducers)
  end

  module_function :mapping, :filtering, :taking, :cat, :compose, :mapcat
end
