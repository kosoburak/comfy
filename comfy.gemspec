# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'comfy/version'

Gem::Specification.new do |spec|
  spec.name          = "comfy"
  spec.version       = Comfy::VERSION
  spec.authors       = ["Michal Kimle", "Ľubomír Košarišťan"]
  spec.email         = ["kimle.michal@gmail.com", "kosoburak@gmail.com"]

  spec.summary       = %q{Tool for building virtual machine images from scratch and their upload to OpenNebula.}
  spec.description   = %q{Tool for building virtual machine images from scratch and their upload to OpenNebula.}
  spec.homepage      = "https://github.com/Misenko/comfy"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", '~> 1.7'
  spec.add_development_dependency "rake", '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0.0'
  spec.add_development_dependency 'simplecov', '~> 0.9.0'
  spec.add_development_dependency 'rubygems-tasks', '~> 0.2.4'

  spec.add_runtime_dependency 'opennebula', '~> 4.6.0'
  spec.add_runtime_dependency 'syslogger', '~> 1.6.0'
  spec.add_runtime_dependency 'settingslogic', '~> 2.0.9'
  spec.add_runtime_dependency 'mixlib-shellout', '~> 2.0.1'
  spec.add_runtime_dependency 'sinatra', '~> 1.4.5'
  spec.add_runtime_dependency 'thin', '~> 1.6.3'
end
