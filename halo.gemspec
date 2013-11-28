# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'halo/version'


Gem::Specification.new do |spec|
  spec.name          = "halo"
  spec.version       = Halo::VERSION
  spec.authors       = ["Adam Hallett"]
  spec.email         = ["harddrivecaddy@gmail.com"]
  spec.description   = %q{Halo Ruby}
  spec.summary       = %q{Halo Ruby}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']
  spec.extensions    = %w[ext/halo/extconf.rb]

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'debugger'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'

  #spec.add_dependency 'micromachine'
  spec.add_dependency 'rake-compiler'
  spec.add_dependency 'ffi'
  #spec.add_dependency 'crypt-tea'
end
