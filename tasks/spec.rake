if ENV['USER'] == 'vagrant'
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
end
