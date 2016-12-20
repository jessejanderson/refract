# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'refract/version'

Gem::Specification.new do |spec|
  spec.name          = "refract"
  spec.version       = Refract::VERSION
  spec.authors       = ["Robert Mosolgo"]
  spec.email         = ["rdmosolgo@gmail.com"]

  spec.summary       = "Visual diffing for web apps, run on your local git history."
  spec.homepage      = "https://github.com/rmosolgo/refract"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.executables   = ["refract"]
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "capybara"

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
