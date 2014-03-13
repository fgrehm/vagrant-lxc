source 'https://rubygems.org'

gemspec

if ENV['USER'] != 'vagrant'
  raise 'vagrant 1.5 is enabled but it has not been fully tested, make sure you run it from within another VM!'
end

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end

group :development, :test do
  gem 'rake'
  # TODO: Update https://github.com/fgrehm/vagrant-lxc/issues/111
  gem 'rspec',        '2.99.0.beta2'
  gem 'coveralls',    require: false
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git'
end

group :plugins do
  gem 'vagrant-lxc',      path: '.'
  if ENV['ACCEPTANCE'] != 'true'
    gem 'vagrant-cachier',  git: 'https://github.com/fgrehm/vagrant-cachier.git'
    gem 'vagrant-pristine', git: 'https://github.com/fgrehm/vagrant-pristine.git'
    gem 'vagrant-omnibus'
  end
end
