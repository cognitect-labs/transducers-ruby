require "transducers/version"

module Enumerable
  def transduce(transducer, reducer, result)
    xform = transducer[reducer]
    each {|input| xform[result, input]}
    result
  end
end

module Transducers
  def mapping(xform)
    ->(reducer){
      ->(result,input){
        reducer[result, xform[input]]
      }
    }
  end

  def filtering(pred)
    ->(reducer){
      ->(result,input){
        pred[input] ? reducer[result, input] : result
      }
    }
  end

  def compose(*fns)
    fn = fns.shift
    fns.empty? ? fn : ->(*args){fn[compose(*fns)[*args]]}
  end

  module_function :mapping, :filtering, :compose
end
