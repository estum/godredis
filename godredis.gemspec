# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = "godredis"
  spec.version       = "0.0.2"
  spec.authors       = ["Tõnis Simo"]
  spec.email         = ["anton.estum@gmail.com"]
  spec.summary       = %q{Godredis: bulk managing multiply Redis instances.}
  spec.description   = %q{Godredis provides unified interface for mass managing 
                          Redis connections which could be initialized in 
                          different modules having each own custom API.}
  spec.homepage      = ""
  spec.license       = "MIT"
  
  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 1.9.3"
  
  spec.add_development_dependency "bundler", "~> 1.6"
  spec.add_development_dependency "rake"
  spec.add_dependency "activesupport", ">= 3.0.0"
end