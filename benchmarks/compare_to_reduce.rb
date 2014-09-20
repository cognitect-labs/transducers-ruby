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

inc    = ->(n){n + 1}
even   = ->(n){n.even?}
append = ->(a,i){a << i}
mapping_inc    = Transducers.mapping(inc)
filtering_even = Transducers.filtering(even)
xform          = Transducers.compose(mapping_inc, filtering_even)
a = 1.upto(1000)

times = 100

Benchmark.benchmark do |bm|
  puts "select"

  3.times do
    bm.report do
      times.times do
        a.select &even
      end
    end
  end

  puts

  puts "filtering"
  3.times do
    bm.report do
      times.times do
        a.transduce(filtering_even, append, [])
      end
    end
  end

  puts

  puts "map"
  3.times do
    bm.report do
      times.times do
        a.map &inc
      end
    end
  end

  puts

  puts "mapping"
  3.times do
    bm.report do
      times.times do
        a.transduce(mapping_inc, append, [])
      end
    end
  end

  puts

  puts "map + select"
  3.times do
    bm.report do
      times.times do
        a.map(&inc).select(&even)
      end
    end
  end

  puts

  puts "mapping + filtering"
  3.times do
    bm.report do
      times.times do
        a.transduce(xform, append, [])
      end
    end
  end
end

__END__


select
   0.010000   0.000000   0.010000 (  0.007921)
   0.010000   0.000000   0.010000 (  0.007963)
   0.000000   0.000000   0.000000 (  0.007914)

filtering
   0.030000   0.000000   0.030000 (  0.021641)
   0.020000   0.000000   0.020000 (  0.025123)
   0.020000   0.000000   0.020000 (  0.023591)

map
   0.010000   0.000000   0.010000 (  0.007441)
   0.010000   0.000000   0.010000 (  0.008807)
   0.010000   0.000000   0.010000 (  0.009467)

mapping
   0.020000   0.000000   0.020000 (  0.027268)
   0.020000   0.000000   0.020000 (  0.028268)
   0.030000   0.000000   0.030000 (  0.026570)

map + select
   0.020000   0.000000   0.020000 (  0.022019)
   0.010000   0.000000   0.010000 (  0.014467)
   0.020000   0.000000   0.020000 (  0.014687)

mapping + filtering
   0.050000   0.000000   0.050000 (  0.047115)
   0.040000   0.000000   0.040000 (  0.047875)
   0.050000   0.000000   0.050000 (  0.048241)
