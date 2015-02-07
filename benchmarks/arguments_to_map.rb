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

size  = 1000

e = 1.upto(size)
a = e.to_a

T = Transducers

Benchmark.ips do |bm|
  { "enum" => e, "array" => a }.each do |label, coll|
    bm.report("map with object (#{label})") do |times|
      i = 0
      while i < times
        T.transduce(T.map(Inc.new), :<<, [], coll)
        i += 1
      end
    end


    bm.report("map with Symbol(#{label})") do |times|
      i = 0
      while i < times
        T.transduce(T.map(:succ), :<<, [], coll)
        i += 1
      end
    end


    bm.report("map with block (#{label})") do |times|
      i = 0
      while i < times
        T.transduce(T.map { |n| n + 1 }, :<<, [], coll)
        i += 1
      end
    end
  end
end
