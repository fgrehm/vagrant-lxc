source 'https://rubygems.org'

gemspec

group :development do
  # TODO: Lock to 1.2.3 once it is out with this fix: https://github.com/mitchellh/vagrant/pull/1685
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'vagrant-cachier'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end


group :development, :test do
  gem 'rake'
  gem 'rspec'
  gem 'rspec-fire',  require: 'rspec/fire'
  gem 'rspec-spies', require: false
  gem 'coveralls',   require: false
end
