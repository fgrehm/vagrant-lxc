raise 'This Rakefile is meant to be used from the dev box' unless ENV['USER'] == 'vagrant'

Dir['./tasks/**/*.rake'].each { |f| load f }

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
  task :default => :coverage
rescue LoadError; end
