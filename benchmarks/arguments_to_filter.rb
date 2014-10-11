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

class Even
  def call(n) n.even? end
end

e = 1.upto(1000)
a = e.to_a

times = 1000

T = Transducers

Benchmark.benchmark do |bm|
  {"enum" => e, "array" => a}.each do |label, coll|
    puts "filter with object (#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(T.filter(Even.new), :<<, [], coll)
        end
      end
    end

    puts "filter with Symbol(#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(T.filter(:even?), :<<, [], coll)
        end
      end
    end

    puts "filter with block (#{label})"
    3.times do
      bm.report do
        times.times do
          T.transduce(T.filter {|n| n.even?}, :<<, [], coll)
        end
      end
    end
  end
end
