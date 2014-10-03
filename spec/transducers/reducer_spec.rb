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

require 'spec_helper'

RSpec.describe Transducers::Reducer do
  Reducer = Transducers::Reducer

  example do
    r = Reducer.new(0, :+)
    expect(r.init).to eq(0)
    expect(r.complete(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end

  example do
    r = Reducer.new(0) {|r,i| r+i}
    expect(r.init).to eq(0)
    expect(r.complete(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end

  example do
    init = Class.new do
      attr_reader :val
      def initialize
        @val = []
      end

      def foo(v)
        @val << v
        self
      end
    end.new
    result = Transducers.transduce(Transducers.map {|n|n+1}, :foo, init, [1,2,3])
    expect(result.val).to eq([2,3,4])
  end
end
