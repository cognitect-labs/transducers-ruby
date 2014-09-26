# Transducers

See http://clojure.org/transducers for background

A transducer is a function or object that transforms a _reducer_: you
hand it a reducer, and it gives you back a transformed reducer. To
understand that, you first need to understand what a _reducer_ is.

### Reducers

In Ruby, reducers, or reducing functions, in this case, are blocks
that we pass to the reduce method, e.g.

```ruby
# sum
[1,2,3].reduce {|result, input| result + input}
# => 6
```

`reduce` iterates over the collection. At each step of the iteration
it passes the result so far (initialized with the first value in the
collection) and the next value in the collection as input to the
block, and the block is expected to return a new result that
incorporates the input.

We can do the same thing with a method that takes two args, an
accumulated result (or initial value), and an input, and then returns
a new accumulated result, e.g.

```ruby
new_result = my_reducer.step(result, input)
```

Transducers require reducers with three different operations:

* `init()` provides an initial value
* `result(result)` can optionally modify the result so far. In most
  cases, it just returns it
* `step(result, input)` incorporates the input into the result so far
  and returns the result so far.

Consider, for example, the reducer that we'd use to sum a collection
of numbers:

```ruby
[1,2,3].reduce {|result, input| result + input}
```

To build that into a transducible reducer, we need to provide it an
initial value.

```ruby
sum = Reducer.new(0) {|r,i|r+i}
sum.init
# => 0
sum.result(5)
# => 5
sum.step(5,3)
# => 8
```
