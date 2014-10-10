# transducers-ruby

[Transducers](http://clojure.org/transducers) are composable algorithmic transformations. They are independent from the context of their input and output sources and specify only the essence of the transformation in terms of an individual element. Because transducers are decoupled from input or output sources, they can be used in many different processes - collections, streams, channels, observables, etc. Transducers compose directly, without awareness of input or creation of intermediate aggregates.

Also see the introductory [blog post](http://blog.cognitect.com/blog/2014/8/6/transducers-are-coming) and this [video](https://www.youtube.com/watch?v=6mTbuzafcII).

## Installation

Until we release a Ruby gem:

    git clone https://github.com/cognitect-labs/transducers-ruby.git
    cd transducers-ruby
    bundle
    rake install

# Usage

    require 'transducers'
    T = Transducers
    T.transduce(T.compose(T.map(:succ), T.filter(:even?)), :<<, [], 0..9)
    # => [2, 4, 6, 8, 10]

See docs for more detail.

## Contributing

This library is open source, developed internally by [Cognitect](http://cognitect.com). Issues can be filed using [GitHub Issues](https://github.com/cognitect-labs/transducers-ruby/issues).

This project is provided without support or guarantee of continued development.
Because transducers-ruby may be incorporated into products or client projects, we prefer to do development internally and do not accept pull requests or patches.

## Copyright and License

Copyright © 2014 Cognitect

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
