guard 'rspec', :spec_paths => ["spec/unit"] do
  watch(%r{^spec/unit/.+_spec\.rb$})
  watch(%r{^lib/vagrant-lxc/(.+)\.rb$}) { |m| "spec/unit/#{m[1]}_spec.rb" }
  watch('spec/unit_helper.rb')          { "spec/unit" }
  watch('spec/spec_helper.rb')          { "spec/unit" }
  watch(%r{^spec/support/(.+)\.rb$})    { "spec/unit" }
end
