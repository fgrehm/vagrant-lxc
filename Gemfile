source 'https://rubygems.org'

gemspec

group :development do
  # We depend on Vagrant for development, but we don't add it as a
  # gem dependency because we expect to be installed within the
  # Vagrant environment itself using `vagrant plugin`.
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'guard'
  gem 'guard-rspec'
  gem 'guard-bundler'
  gem 'guard-ctags-bundler'
  gem 'rb-inotify'
  gem 'simplecov', require: false
end


group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-fire',  require: 'rspec/fire'
  gem 'rspec-spies', require: false
end
