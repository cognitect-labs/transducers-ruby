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
require 'benchmark/ips'

class Inc
  def call(n) n + 1 end
end

class Even
  def call(n) n.even? end
end

map_inc             = Transducers.map(Inc.new)
filter_even         = Transducers.filter(Even.new)
map_inc_filter_even = Transducers.compose(map_inc, filter_even)
e = 1.upto(1000)
a = e.to_a

T = Transducers

Benchmark.ips do |bm|
  { "enum" => e, "array" => a }.each do |label, coll|
    bm.report("select (#{label})") do |times|
      i = 0
      while i < times
        coll.select { |n| n.even? }
        i += 1
      end
    end

    bm.report("filter (#{label})") do |times|
      i = 0
      while i < times
        T.transduce(filter_even, :<<, [], coll)
        i += 1
      end
    end
  end

  bm.compare!
end


Benchmark.ips do |bm|
  { "enum" => e, "array" => a }.each do |label, coll|
    bm.report("map (#{label})") do |times|
      i = 0
      while i < times
        coll.map { |n| n + 1 }
        i += 1
      end
    end

    bm.report("T. map (#{label})") do |times|
      i = 0
      while i < times
        T.transduce(map_inc, :<<, [], coll)
        i += 1
      end
    end
  end

  bm.compare!
end

Benchmark.ips do |bm|
  { "enum" => e, "array" => a }.each do |label, coll|
    bm.report("map + select (#{label})") do |times|
      i = 0
      while i < times
        coll.
          map { |n| n + 1 }.
          select { |n| n.even? }
        i += 1
      end
    end

    bm.report("map + filter (#{label})") do |times|
      i = 0
      while i < times
        T.transduce(map_inc_filter_even, :<<, [], coll)
        i += 1
      end
    end
  end

  bm.compare!
end

__END__

Calculating -------------------------------------
       select (enum)     1.005k i/100ms
       filter (enum)   315.000  i/100ms
      select (array)     1.218k i/100ms
      filter (array)   308.000  i/100ms
-------------------------------------------------
       select (enum)     10.101k (± 2.0%) i/s -     51.255k
       filter (enum)      3.185k (± 3.1%) i/s -     16.065k
      select (array)     12.824k (± 7.9%) i/s -     64.554k
      filter (array)      3.314k (± 2.0%) i/s -     16.632k

Comparison:
      select (array):    12824.3 i/s
       select (enum):    10101.5 i/s - 1.27x slower
      filter (array):     3313.8 i/s - 3.87x slower
       filter (enum):     3184.7 i/s - 4.03x slower

Calculating -------------------------------------
          map (enum)     1.002k i/100ms
       T. map (enum)   287.000  i/100ms
         map (array)     1.431k i/100ms
      T. map (array)   278.000  i/100ms
-------------------------------------------------
          map (enum)     10.249k (± 3.2%) i/s -     52.104k
       T. map (enum)      2.757k (± 2.7%) i/s -     13.776k
         map (array)     13.956k (± 3.7%) i/s -     70.119k
      T. map (array)      2.817k (± 3.1%) i/s -     14.178k

Comparison:
         map (array):    13956.1 i/s
          map (enum):    10248.6 i/s - 1.36x slower
      T. map (array):     2817.3 i/s - 4.95x slower
       T. map (enum):     2756.9 i/s - 5.06x slower

Calculating -------------------------------------
 map + select (enum)   550.000  i/100ms
 map + filter (enum)   219.000  i/100ms
map + select (array)   659.000  i/100ms
map + filter (array)   222.000  i/100ms
-------------------------------------------------
 map + select (enum)      5.647k (± 1.8%) i/s -     28.600k
 map + filter (enum)      2.208k (± 1.6%) i/s -     11.169k
map + select (array)      6.673k (± 3.4%) i/s -     33.609k
map + filter (array)      2.272k (± 2.4%) i/s -     11.544k

Comparison:
map + select (array):     6673.4 i/s
 map + select (enum):     5646.8 i/s - 1.18x slower
map + filter (array):     2271.9 i/s - 2.94x slower
 map + filter (enum):     2208.1 i/s - 3.02x slower
