# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'halo/version'

Gem::Specification.new do |spec|
  spec.name          = 'halo'
  spec.version       = Halo::VERSION
  spec.authors       = ['Adam Hallett']
  spec.email         = ['adam.t.hallett@gmail.com']
  spec.description   = %q{Halo Ruby}
  spec.summary       = %q{Halo Ruby}
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'rubocop'

  spec.add_dependency 'rake-compiler'
  spec.add_dependency 'micromachine', '>= 2.0.0'
  spec.add_dependency 'bindata'
  spec.add_dependency 'byebug'
end
