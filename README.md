# Transducers

See http://clojure.org/transducers for background

A transducer is a function or object that transforms a _reducer_: you
hand it a reducer, and it gives you back a transformed reducer.

### Reducers

A reducing function accepts the result so far and the next input in a
reducing operation. In Ruby, these are the blocks that we pass to the
`reduce` (a.k.a. `inject`) method, e.g.

```ruby
# sum
[1,2,3].reduce(0) {|result, input| result + input}
# => 6
```

`reduce` iterates over the collection (`[1,2,3]`). At each step of the
iteration it passes the result so far (initialized with the first
argument to `reduce` in this example) and the next value in the
collection as input to the reducing function (the block passed to
`reduce`), which is expected to return a new result that incorporates
the input.

For the purposes of transducers, a reducer is an object with three operations:

* `init()` provides an initial value.
* `result(result)` can optionally modify the result so far. In most
  cases, it just returns it.
* `step(result, input)` is the reducing operation.

And a transducer is an object with a `reducer` method that accepts a
reducer and returns a modified reducer e.g.

```ruby
sum = Transducers::Reducer.new(0) {|result, input| result + input}
mapping_inc = Transducers.mapping {|n| n + 1}
```

We can pass these two to the `transduce` method like this:

```ruby
initial_value = 0
coll = 1..100
Transducers.transduce(mapping_inc, sum, initial_value, coll)
```

Internally, the transduce method passes `sum` to `mapping_inc`'s
`reduce` method, generating a new reducer that, at each step,
increments the next number in the input (`mapping_inc`) and then adds
it to the result so far (`sum`), which is initialized with the 3rd
argument to `transduce`, the initial value.

`transduce` can also accept just 3 arguments:

```ruby
Transducers.transduce(mapping_inc, sum, 1..100)
```

In this case, since there is no initial value, transduce asks the
reducer for the initial value by calling its `init` method. The `sum`
reducer returns 0, which was the first argument to `Reducer.new`,
above.

### Why???

Imagine we want to double every number in a collection and then
calculate the sum. Here's one way we might do this in Ruby:

```ruby
[1,2,3].
  map    {|n| n * 2}.
  reduce {|sum, n| sum + n}
```

Seems fine, but there is a subtle efficiency problem. We start off
with the collection `[1,2,3]`, build a new collection `[2,4,6]`, and
then build a numeric result. Now imagine this scenario:

```ruby
[1,2,3].
  map    {|n| n * 3}.
  select {|n| n.even?}.
  reduce {|sum, n| sum + n}
```

Now we're building `[3,6,9]`, then `[6]`, then `6`. Here's the same
process with transducers:

```ruby
transduce(
  compose(mapping {|n| n * 3},filtering(:even?)),
  Reducer.new(0) {|r,i|r+i},
  [1,2,3])
```

Here's what happens under the hood:

```ruby
coll = [1,2,3]
init = 0
result_so_far = 0

# step 1
input = 1
xformed = input * 3
if xformed.even? # which it is not
  result_so_far = result_so_far + xformed
end
result_so_far
# => 0

# step 2
input = 2
xformed = input * 3
if xformed.even? # which it is
  result_so_far = result_so_far + xformed
end
result_so_far
# => 6

# step 3
input = 3
xformed = input * 3
if xformed.even? # which it is not
  result_so_far = result_so_far + xformed
end
result_so_far
# => 6
```

Note that there are no intermediate collections here! That's one
benefit of transducers.

Here's another example:

```ruby
(1..1_000_000).
  select {|x| x.even?}.
  map {|x| x * 2}.
  take(10).
  reduce {|s,i|s+i}

# .. vs

transduce(compose(filtering(:even?),
                  mapping {|x| x * 2},
                  taking(10)),
          Transducers::Reducer.new(0) {|r,i|r+i},
          1..1_000_000)
```

Here the chained iterator example generates 3 intermediate collections
of 500k 500k, and 10 values, respectively. The Transducers example
generates no new collections, and stops iterating over the intial
collection as soon as the taking transducer has seen 10 values; a
clear win for both memory and processing cycle consumption.
