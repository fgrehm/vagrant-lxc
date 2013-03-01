desc 'Run specs with code coverage enabled'
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["spec"].execute
end
