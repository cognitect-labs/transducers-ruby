require "transducers/version"

module Enumerable
  def transduce(transducer, reducer, result)
    t = transducer[reducer]
    n = size
    while n > 0
      return result.val if Transducers::Reduced === result
      input = self[size - n]
      result = t[result, input]
      n -= 1
    end
    result
  end
end

class Enumerator
  def transduce(transducer, reducer, result)
    t = transducer[reducer]
    each do |input|
      return result.val if Transducers::Reduced === result
      result = t[result, input]
    end
    result
  end
end

module Transducers
  class Reduced
    attr_reader :val
    def initialize(val)
      @val = val
    end
  end

  def mapping(xform)
    ->(reducer){
      ->(*args){
        case args.size
        when 0
          reducer[]
        when 1
          reducer[args[0]]
        when 2
          result = args[0]
          input = args[1]
          reducer[result, xform[input]]
        end
      }
    }
  end

  def filtering(pred)
    ->(reducer){
      ->(*args){
        case args.size
        when 0
          reducer[]
        when 1
          reducer[args[0]]
        when 2
          result = args[0]
          input = args[1]
          pred[input] ? reducer[result, input] : result
        end
      }
    }
  end

  def taking(n)
    ->(reducer){
      current = n
      ->(*args){
        case args.size
        when 0
          reducer[]
        when 1
          reducer[args[0]]
        when 2
          prev = current
          current = current - 1
          result = prev > 0 ? reducer[*args] : args[0]
          if current == 0
            Reduced.new args[0]
          else
            args[0]
          end
        end
      }
    }
  end

  def compose(*fns)
    fn = fns.shift
    fns.empty? ? fn : ->(*args){fn[compose(*fns)[*args]]}
  end

  module_function :mapping, :filtering, :compose, :taking
end
