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
small  = ->(n){n < 800}
append = ->(a,i){a << i}
mapping_inc    = Transducers.mapping(inc)
filtering_even = Transducers.filtering(even)
xform          = Transducers.compose(mapping_inc, filtering_even)
e = 1.upto(1000)
a = e.to_a

times = 100

Benchmark.benchmark do |bm|
  {"enum" => e, "array" => a}.each do |label, coll|
    puts "select (#{label})"

    3.times do
      bm.report do
        times.times do
          coll.select &even
        end
      end
    end

    puts

    puts "filtering (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.transduce(filtering_even, append, [])
        end
      end
    end

    puts

    puts "map (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.map &inc
        end
      end
    end

    puts

    puts "mapping (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.transduce(mapping_inc, append, [])
        end
      end
    end

    puts

    puts "map + select (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.map(&inc).select(&even)
        end
      end
    end

    puts

    puts "mapping + filtering (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.transduce(xform, append, [])
        end
      end
    end

    puts
  end
end

__END__

select (enum)
   0.010000   0.000000   0.010000 (  0.008059)
   0.010000   0.000000   0.010000 (  0.008263)
   0.010000   0.000000   0.010000 (  0.008287)

filtering (enum)
   0.020000   0.000000   0.020000 (  0.028182)
   0.030000   0.000000   0.030000 (  0.027931)
   0.030000   0.000000   0.030000 (  0.027978)

map (enum)
   0.010000   0.000000   0.010000 (  0.007463)
   0.000000   0.000000   0.000000 (  0.007692)
   0.010000   0.000000   0.010000 (  0.007714)

mapping (enum)
   0.030000   0.000000   0.030000 (  0.031837)
   0.030000   0.000000   0.030000 (  0.032123)
   0.040000   0.000000   0.040000 (  0.035496)

map + select (enum)
   0.010000   0.000000   0.010000 (  0.014277)
   0.020000   0.000000   0.020000 (  0.014433)
   0.010000   0.000000   0.010000 (  0.017674)

mapping + filtering (enum)
   0.050000   0.000000   0.050000 (  0.049372)
   0.050000   0.000000   0.050000 (  0.050552)
   0.050000   0.000000   0.050000 (  0.049580)

select (array)
   0.010000   0.000000   0.010000 (  0.006366)
   0.010000   0.000000   0.010000 (  0.006525)
   0.000000   0.000000   0.000000 (  0.006869)

filtering (array)
   0.030000   0.000000   0.030000 (  0.029771)
   0.030000   0.000000   0.030000 (  0.027980)
   0.030000   0.000000   0.030000 (  0.033978)

map (array)
   0.010000   0.000000   0.010000 (  0.005494)
   0.000000   0.000000   0.000000 (  0.005546)
   0.010000   0.000000   0.010000 (  0.005895)

mapping (array)
   0.030000   0.000000   0.030000 (  0.031703)
   0.030000   0.000000   0.030000 (  0.031619)
   0.040000   0.000000   0.040000 (  0.031852)

map + select (array)
   0.010000   0.000000   0.010000 (  0.011600)
   0.010000   0.000000   0.010000 (  0.011653)
   0.010000   0.000000   0.010000 (  0.012087)

mapping + filtering (array)
   0.060000   0.010000   0.070000 (  0.056059)
   0.050000   0.000000   0.050000 (  0.050310)
   0.050000   0.000000   0.050000 (  0.050120)
