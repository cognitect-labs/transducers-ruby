require "transducers/version"

module Enumerable
  def transduce(transducer, reducer, init)
    reduce(init, &transducer.call(reducer))
  end
end

module Transducers
  def mapping(xform)
    ->(reducer){
      ->(result,input){
        reducer.call(result, xform.call(input))
      }
    }
  end

  def filtering(pred)
    ->(reducer){
      ->(result,input){
        pred.call(input) ? reducer.call(result, input) : result
      }
    }
  end

  def compose(*fns)
    fn = fns.shift
    fns.empty? ? fn : ->(*args){ fn[compose(*fns)[*args]]}
  end

  module_function :mapping, :filtering, :compose
end
