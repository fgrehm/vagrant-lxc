guard 'bundler' do
  watch('Gemfile')
  watch(/^.+\.gemspec/)
end

guard 'ctags-bundler', :src_path => ["lib"] do
  watch(/^(lib|spec\/support)\/.*\.rb$/)
  watch('Gemfile.lock')
end

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/vagrant-lxc/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/unit_helper.rb')          { "spec/unit" }
  watch('spec/acceptance_helper.rb')    { "spec/acceptance" }
  watch('spec/spec_helper.rb')          { "spec/" }
  watch(%r{^spec/support/(.+)\.rb$})    { "spec/" }
end
