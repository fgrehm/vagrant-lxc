begin
  require 'rspec/core/rake_task'
  require 'coveralls/rake/task'

  desc 'Run all specs'
  task :spec => ['spec:unit', 'spec:acceptance']

  desc 'Default task which runs all specs with code coverage enabled'
  task :default => ['spec:set_coverage', 'spec']

  Coveralls::RakeTask.new
  task :ci => ['spec:set_coverage', 'spec:unit', 'coveralls:push']
rescue LoadError; end

namespace :spec do
  task :set_coverage do
    ENV['COVERAGE'] = 'true'
  end

  def types
    dirs = Dir['./spec/**/*_spec.rb'].map { |f| f.sub(/^\.\/(spec\/\w+)\/.*/, '\\1') }.uniq
    Hash[dirs.map { |d| [d.split('/').last, d] }]
  end
  types.each do |type, dir|
    desc "Run the code examples in #{dir}"
    RSpec::Core::RakeTask.new(type) do |t|
      # Tells rspec-fire to verify if constants used really exist
      ENV['VERIFY_CONSTANT_NAMES'] = '1'

      t.pattern = "./#{dir}/**/*_spec.rb"
    end
  end
end
