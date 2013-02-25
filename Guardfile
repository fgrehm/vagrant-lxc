# A sample Guardfile
# More info at https://github.com/guard/guard#readme

raise 'You should start guard from the dev box!' unless ENV['USER'] == 'vagrant'

guard 'rspec' do
  watch(%r{^spec/.+_spec\.rb$})
  watch('spec/spec_helper.rb') { 'spec' }
  watch('lib/provider')        { 'spec' }
end
