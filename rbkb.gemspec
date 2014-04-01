# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rbkb/version'

Gem::Specification.new do |spec|
  spec.name          = "rbkb"
  spec.version       = Rbkb::VERSION
  spec.authors       = ["Eric Monti"]
  spec.email         = ["monti@bluebox.com"]
  spec.description   = "Rbkb is a collection of ruby-based pen-testing and reversing tools. Inspired by Matasano Blackbag."
  spec.summary       = "Rbkb is a collection of ruby-based pen-testing and reversing tools"
  spec.homepage      = "http://emonti.github.com/rbkb"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake", "~> 0"
  spec.add_development_dependency "rspec", "~> 0"
end
