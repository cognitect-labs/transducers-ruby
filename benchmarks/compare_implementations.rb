# Copyright 2014 Cognitect. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS-IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

$LOAD_PATH << File.expand_path("../../lib", __FILE__)
require 'transducers'
require 'benchmark'

class Inc
  def xform(n) n + 1 end
end

mapping_inc         = Transducers.mapping(Inc.new)
filtering_even      = Transducers.filtering(:even?)
map_inc_filter_even = Transducers.compose(mapping_inc, filtering_even)
e = 1.upto(1000)
a = e.to_a

times = 100

module WithEach
  def transduce(transducer, reducer, result)
    r = transducer.reducer(Transducers.reducer(reducer))
    each { |input| result = r.step(result, input) }
    result
  end
end

module WithReduce
  def transduce(transducer, reducer, result)
    r = transducer.reducer(Transducers.reducer(reducer))
    reduce(result) {|res,inp| r.step(res,inp)}
  end
end

module WithIndexing
  def transduce(transducer, reducer, result)
    r = transducer.reducer(Transducers.reducer(reducer))
    for i in 0...size
      input = self[i]
      result = r.step(result, input)
    end
    result
  end
end

[Array, Enumerator, Range].each do |klass|
  klass.class_eval do
    undef_method :transduce
  end
end

Benchmark.benchmark do |bm|
  {"enum" => e, "array" => a, "range" => 1..times}.each do |label, coll|
    [WithEach, WithReduce, WithIndexing].each do |mod|
      next if mod == WithIndexing && %w[range enum].include?(label)
      puts
      puts "****** #{label} using #{mod}"
      coll.extend mod
      puts "filtering (#{label})"
      3.times do
        bm.report do
          times.times do
            coll.transduce(filtering_even, :<<, [])
          end
        end
      end
      puts "mapping (#{label})"
      3.times do
        bm.report do
          times.times do
            coll.transduce(mapping_inc, :<<, [])
          end
        end
      end
      puts "mapping + filtering (#{label})"
      3.times do
        bm.report do
          times.times do
            coll.transduce(map_inc_filter_even, :<<, [])
          end
        end
      end
    end
  end
end
