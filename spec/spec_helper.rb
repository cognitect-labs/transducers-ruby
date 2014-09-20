$LOAD_PATH << 'lib'
require 'transducers'

RSpec.configure do |config|
  config.filter_run :focus
  config.run_all_when_everything_filtered = true
  config.order = :random
  Kernel.srand config.seed
end
