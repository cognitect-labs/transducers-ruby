# Transducers

See http://clojure.org/transducers for background

A transducer is a function or object that transforms a _reducer_: you
hand it a reducer, and it gives you back a transformed reducer. To
understand that, you first need to understand what a _reducer_ is.

### Reducers

In Ruby, reducers, or reducing functions, are blocks
that we pass to the reduce method, e.g.

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

We can accomplish the same task at each step of the iteration with a
method that takes two args, an accumulated result (or initial value),
and an input, and then returns a new accumulated result, e.g.

```ruby
new_result = my_reducer.step(result_so_far, input)
```

And then we can implement our own `reduce` in terms of `each`, e.g.

```ruby
sum = Class.new do
  def step(result, input)
    result + input
  end
end.new

def my_reduce(reducer, initial_value, collection)
  result = initial_value
  collection.each {|i| result = reducer.step(result,i)}
  result
end
```

Now what if we wanted to double each number before adding them up?
Here's how we'd do that in Ruby:

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
  :+,
  0,
  [1,2,3])
```

Here, the _reducer_ is `:+`, which is applied at each step to the
result so far and the input, e.g

```ruby
coll = [1,2,3]
init = 0
result_so_far = 0

# step 1
input = 1
xformed = input * 3
if xformed.even? # which it is not
  result_so_far = result_so_far + xformed
result_so_far
# => 0

# step 2
input = 2
xformed = input * 3
if xformed.even? # which it is
  result_so_far = result_so_far + xformed
result_so_far
# => 6

# step 3
input = 3
xformed = input * 3
if xformed.even? # which it is not
  result_so_far = result_so_far + xformed
result_so_far
# => 6
```

Note that there are no intermediate collections here! That's one
benefit of transducers.

### Transducible reducers

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
