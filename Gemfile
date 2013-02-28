source 'https://rubygems.org'

unless ENV['USER'] == 'vagrant'
  puts 'This Gemfile is meant to be used from the dev box'
  exit 1
end

gemspec

gem 'vagrant', path: './vagrant'
gem 'rake'
gem 'net-ssh'
gem 'rspec'
gem 'rspec-fire', require: 'rspec/fire'
gem 'rspec-spies', require: false
gem 'simplecov', require: false
gem 'guard'
gem 'guard-rspec'
gem 'guard-bundler'
gem 'guard-ctags-bundler'
gem 'rb-inotify'
gem 'log4r'
