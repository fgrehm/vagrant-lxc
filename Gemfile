source 'https://rubygems.org'

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end

group :development, :test do
  gem 'rake'
  gem 'rspec',        '2.99.0'
  gem 'coveralls',    require: (ENV['COVERAGE'] == 'true')
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git'
end

group :plugins do
  acceptance = (ENV['ACCEPTANCE'] == 'true')
  gem 'vagrant-cachier',  git: 'https://github.com/fgrehm/vagrant-cachier.git',  require: !acceptance
  gem 'vagrant-pristine', git: 'https://github.com/fgrehm/vagrant-pristine.git', require: !acceptance
  gem 'vagrant-omnibus',  require: !acceptance
  gemspec
end
