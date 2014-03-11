source 'https://rubygems.org'

gemspec

group :development do
  gem 'vagrant',          github: 'mitchellh/vagrant'
  gem 'vagrant-spec',     github: 'mitchellh/vagrant-spec'
  gem 'vagrant-cachier',  github: 'fgrehm/vagrant-cachier'
  gem 'vagrant-pristine', github: 'fgrehm/vagrant-pristine'
  gem 'vagrant-omnibus'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end


group :development, :test do
  gem 'rake'
  # Update https://github.com/fgrehm/vagrant-lxc/issues/111
  gem 'rspec',       '2.99.0.beta2'
  gem 'coveralls',   require: false
end
