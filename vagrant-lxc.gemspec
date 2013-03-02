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
  gem.homepage      = "https://github.com/fgrehm/vagrant-lxc"

  gem.files = `git ls-files`.split($/)
  gem.files << `cd vendor/vagrant && git ls-files`.split($/).map{|file| "vendor/vagrant/#{file}"}

  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  # Vagrant's dependencies
  gem.add_dependency "childprocess", "~> 0.3.7"
  gem.add_dependency "erubis", "~> 2.7.0"
  gem.add_dependency "i18n", "~> 0.6.0"
  gem.add_dependency "json", ">= 1.5.1", "< 1.8.0"
  gem.add_dependency "log4r", "~> 1.1.9"
  gem.add_dependency "net-ssh", "~> 2.2.2"
  gem.add_dependency "net-scp", "~> 1.0.4"
end
