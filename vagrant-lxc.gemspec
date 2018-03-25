# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vagrant-lxc/version'

Gem::Specification.new do |gem|
  gem.name          = "vagrant-lxc-2.1-patch"
  gem.version       = Vagrant::LXC::VERSION
  gem.authors       = ["Fabio Rehm"]
  gem.email         = ["fgrehm@gmail.com"]
  gem.description   = %q{Linux Containers provider for Vagrant.  Patched for LXC 2.1+}
  gem.summary       = gem.description
  gem.license       = 'MIT'
  gem.homepage      = "https://github.com/kevcenteno/vagrant-lxc"

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]
end
