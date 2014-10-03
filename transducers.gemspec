# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "transducers"
  spec.version       = "0.0.dev"
  spec.authors       = ["David Chelimsky"]
  spec.email         = ["dchelimsky@cognitect.com"]
  spec.summary       = %q{Transducers for Ruby}
  spec.description   = %q{Transducers, composable algorithmic transformations}
  spec.homepage      = "https://github.com/cognitect-labs/transducers-ruby"
  spec.license       = "Apache License 2.0"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler",            "~> 1.7"
  spec.add_development_dependency "rake",               "~> 10.0"
  spec.add_development_dependency "rspec",              "~> 3.0"
  spec.add_development_dependency "yard",               "~> 0.8.7.4"
  spec.add_development_dependency "redcarpet",          "~> 3.1.1"
  spec.add_development_dependency "yard-redcarpet-ext", "~> 0.0.3"

  private_key = File.expand_path(File.join(ENV['HOME'], '.gem/transit-ruby/private-key.pem'))
  public_key  = File.expand_path(File.join(ENV['HOME'], '.gem/transit-ruby/public-key.pem'))

  if File.exist?(private_key) && ENV['SIGN'] == 'true'
    spec.signing_key = private_key
    spec.cert_chain  = [public_key]
  end
end
