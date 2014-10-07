$LOAD_PATH << 'lib'
require 'transducers'

T = Transducers

p T.transduce(
              T.compose(
                        T.map(:succ),
                        T.filter(:even?),
                        T.take(100000)),
              :+, 0, 1..1000000000)
