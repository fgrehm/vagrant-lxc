# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-lxc/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-lxc"
  gem.version       = Vagrant::LXC::VERSION
  gem.authors       = ["Fabio Rehm"]
  gem.email         = ["fgrehm@gmail.com"]
  gem.description   = %q{Linux Containers provider for Vagrant}
  gem.summary       = gem.description
  gem.license       = 'MIT'
  gem.homepage      = "https://github.com/fgrehm/vagrant-lxc"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
