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
  gem 'coveralls',    require: (ENV['COVERAGE'] == 'true')
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git'
end

group :plugins do
  gem 'vagrant-lxc',      path: '.'
  acceptance = (ENV['ACCEPTANCE'] == 'true')
  gem 'vagrant-cachier',  git: 'https://github.com/fgrehm/vagrant-cachier.git',  require: !acceptance
  gem 'vagrant-pristine', git: 'https://github.com/fgrehm/vagrant-pristine.git', require: !acceptance
  gem 'vagrant-omnibus',  require: !acceptance
end
