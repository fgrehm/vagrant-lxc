Dir['./tasks/**/*.rake'].each { |f| load f }

require 'bundler/gem_tasks'

task :ci => ['spec:unit']
