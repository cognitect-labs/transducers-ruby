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
  def call(n) n + 1 end
end

class Even
  def call(n) n.even? end
end

map_inc         = Transducers.map(Inc.new)
filter_even      = Transducers.filter(Even.new)
map_inc_filter_even = Transducers.compose(map_inc, filter_even)
e = 1.upto(1000)
a = e.to_a

times = 100

T = Transducers

Benchmark.benchmark do |bm|
  {"enum" => e, "array" => a}.each do |label, coll|
    puts "select (#{label})"

    3.times do
      bm.report do
        times.times do
          coll.select {|n| n.even?}
        end
      end
    end

    puts "filter (#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(filter_even, :<<, [], coll)
        end
      end
    end

    puts

    puts "map (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.map {|n| n + 1}
        end
      end
    end

    puts "map (#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(map_inc, :<<, [], coll)
        end
      end
    end

    puts

    puts "map + select (#{label})"
    3.times do
      bm.report do
        times.times do
          coll.
            map    {|n| n + 1}.
            select {|n| n.even?}
        end
      end
    end

    puts "map + filter (#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(map_inc_filter_even, :<<, [], coll)
        end
      end
    end

    puts
  end
end

__END__

select (enum)
   0.010000   0.000000   0.010000 (  0.008299)
   0.010000   0.000000   0.010000 (  0.007843)
   0.000000   0.000000   0.000000 (  0.007821)
filter (enum)
   0.020000   0.000000   0.020000 (  0.017747)
   0.020000   0.000000   0.020000 (  0.019915)
   0.020000   0.000000   0.020000 (  0.019416)

map (enum)
   0.010000   0.000000   0.010000 (  0.008053)
   0.010000   0.000000   0.010000 (  0.007952)
   0.010000   0.000000   0.010000 (  0.009550)
map (enum)
   0.020000   0.000000   0.020000 (  0.021479)
   0.020000   0.000000   0.020000 (  0.020805)
   0.020000   0.000000   0.020000 (  0.023205)

map + select (enum)
   0.010000   0.000000   0.010000 (  0.015156)
   0.020000   0.000000   0.020000 (  0.016545)
   0.010000   0.010000   0.020000 (  0.019388)
map + filter (enum)
   0.030000   0.000000   0.030000 (  0.026530)
   0.030000   0.000000   0.030000 (  0.025563)
   0.020000   0.000000   0.020000 (  0.027893)

select (array)
   0.010000   0.000000   0.010000 (  0.006520)
   0.010000   0.000000   0.010000 (  0.006570)
   0.000000   0.000000   0.000000 (  0.007032)
filter (array)
   0.020000   0.000000   0.020000 (  0.022639)
   0.030000   0.000000   0.030000 (  0.023813)
   0.020000   0.000000   0.020000 (  0.022440)

map (array)
   0.010000   0.000000   0.010000 (  0.005880)
   0.000000   0.000000   0.000000 (  0.005613)
   0.010000   0.000000   0.010000 (  0.005294)
map (array)
   0.020000   0.000000   0.020000 (  0.024443)
   0.030000   0.000000   0.030000 (  0.023856)
   0.020000   0.000000   0.020000 (  0.024172)

map + select (array)
   0.010000   0.000000   0.010000 (  0.012158)
   0.010000   0.000000   0.010000 (  0.012061)
   0.020000   0.000000   0.020000 (  0.014131)
map + filter (array)
   0.020000   0.000000   0.020000 (  0.026898)
   0.030000   0.000000   0.030000 (  0.025745)
   0.030000   0.000000   0.030000 (  0.028196)
