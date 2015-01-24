# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'crdt/version'

Gem::Specification.new do |spec|
  spec.name        = 'crdt'
  spec.version     = CRDT::VERSION

  spec.licenses    = ['MIT']
  spec.summary     = "Convergent/Commutative Replicated Data Types"
  spec.description = "This library provides naive implementations of common CRDTs"

  spec.authors     = ["Steven Karas"]
  spec.email       = 'steven.karas@gmail.com'
  spec.homepage    = 'https://rubygems.org/gems/crdt'

  spec.files       = `git ls-files -z`.split("\x0")
  spec.executables = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files  = spec.files.grep(%r{^(test|spec|features)/})

  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
end
