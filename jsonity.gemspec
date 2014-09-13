# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'jsonity/version'

Gem::Specification.new do |spec|
  spec.name          = 'jsonity'
  spec.version       = Jsonity::VERSION
  spec.authors       = ['Yuki Iwanaga']
  spec.email         = ['yuki@creasty.com']
  spec.summary       = 'The most sexy language for building JSON in Ruby'
  spec.description   = 'The most sexy language for building JSON in Ruby'
  spec.homepage      = 'https://github.com/creasty/jsonity'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake', '~> 10.3'
end
