raise 'This Rakefile is meant to be used from the dev box' unless ENV['USER'] == 'vagrant'

Dir['./tasks/**/*.rake'].each { |f| load f }

task :default => :spec
