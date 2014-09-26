require 'spec_helper'

RSpec.describe Transducers::Reducer do
  Reducer = Transducers::Reducer

  example do
    r = Reducer.new(:+, 0)
    expect(r.init).to eq(0)
    expect(r.result(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end

  example do
    r = Reducer.new(0) {|r,i| r+i}
    expect(r.init).to eq(0)
    expect(r.result(1)).to eq(1)
    expect(r.step(3,7)).to eq(10)
  end
end
