source 'https://rubygems.org'

gemspec

group :development do
  gem 'vagrant',          github: 'mitchellh/vagrant'
  gem 'vagrant-cachier',  github: 'fgrehm/vagrant-cachier'
  gem 'vagrant-pristine', github: 'fgrehm/vagrant-pristine'
  gem 'vagrant-omnibus'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end


group :development, :test do
  gem 'rake'
  gem 'rspec',       '~> 2.13.0'
  gem 'rspec-fire',  require: 'rspec/fire'
  gem 'rspec-spies', require: false
  gem 'coveralls',   require: false
end
