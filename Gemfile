source 'https://rubygems.org'

gemspec

if ENV['USER'] != 'vagrant'
  raise 'vagrant 1.5 is enabled but it has not been fully tested, make sure you run it from within another VM!'
end

group :development do
  gem 'vagrant', github: 'mitchellh/vagrant'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end

group :development, :test do
  gem 'rake'
  # Update https://github.com/fgrehm/vagrant-lxc/issues/111
  gem 'rspec',        '2.99.0.beta2'
  gem 'coveralls',    require: false
  gem 'vagrant-spec', github: 'mitchellh/vagrant-spec'
end

group :plugins do
  gem 'vagrant-lxc',      path: '.'
  gem 'vagrant-cachier',  github: 'fgrehm/vagrant-cachier'
  gem 'vagrant-pristine', github: 'fgrehm/vagrant-pristine'
  gem 'vagrant-omnibus'
end
