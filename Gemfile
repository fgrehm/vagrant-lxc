source 'https://rubygems.org'

group :development do
  gem 'vagrant', git: 'https://github.com/mitchellh/vagrant.git', tag: 'v1.8.7'
  gem 'guard'
  gem 'guard-rspec'
  gem 'rb-inotify'
end

group :development, :test do
  gem 'rake', '~> 10.4.2'
  gem 'rspec', '~> 2.99.0'
  gem 'coveralls', '~> 0.7.2', require: (ENV['COVERAGE'] == 'true')
  # The is the ref *just* before we switch to childprocess 0.6, which conflicts with vagrant 1.8 deps.
  gem 'vagrant-spec', git: 'https://github.com/mitchellh/vagrant-spec.git', ref: '5006bc73cd8796465ca09307d4774f8ec8375aa0'
end

group :plugins do
  acceptance = (ENV['ACCEPTANCE'] == 'true')
  gem 'vagrant-cachier',  git: 'https://github.com/fgrehm/vagrant-cachier.git',  require: !acceptance
  gem 'vagrant-pristine', git: 'https://github.com/fgrehm/vagrant-pristine.git', require: !acceptance
  gem 'vagrant-omnibus',  require: !acceptance
  gemspec
end
