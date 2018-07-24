source 'https://rubygems.org'

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end

group :development, :test do
  gem 'rake', '~> 10.4.2'
  gem 'rspec', '~> 3.5.0'
  gem 'coveralls', '~> 0.7.2', require: (ENV['COVERAGE'] == 'true')
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git'
end

group :plugins do
  acceptance = (ENV['ACCEPTANCE'] == 'true')
  gem 'vagrant-cachier',  git: 'https://github.com/fgrehm/vagrant-cachier.git',  require: !acceptance
  gem 'vagrant-pristine', git: 'https://github.com/fgrehm/vagrant-pristine.git', require: !acceptance
  gem 'vagrant-omnibus',  require: !acceptance
  gemspec
end
